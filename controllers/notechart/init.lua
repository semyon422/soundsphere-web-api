local Notecharts = require("models.notecharts")
local notecharts_c = require("controllers.notecharts")
local Files = require("models.files")
local Formats = require("enums.formats")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")
local util = require("util")
local http = require("lapis.nginx.http")
local config = require("lapis.config").get()
local lapis_util = require("lapis.util")
local to_json = lapis_util.to_json
local from_json = lapis_util.from_json

local additions = {
	scores = require("controllers.notechart.scores"),
	difftables = require("controllers.notechart.difftables"),
	leaderboards = require("controllers.notechart.leaderboards"),
}

local notechart_c = Controller:new()

notechart_c.path = "/notecharts/:notechart_id[%d]"
notechart_c.methods = {"GET", "PATCH"}

notechart_c.context.GET = {"notechart"}
notechart_c.policies.GET = {{"permit"}}
notechart_c.validations.GET = {}
util.add_additions_validations(additions, notechart_c.validations.GET)
util.add_belongs_to_validations(Notecharts.relations, notechart_c.validations.GET)
notechart_c.GET = function(self)
	local notechart = self.context.notechart

	util.load_additions(self, notechart, additions)
	util.get_relatives(notechart, self.params, true)

	return {json = {notechart = notechart:to_name()}}
end

notechart_c.set_notechart_from_metadata = function(notechart_file, response_notechart)
	local notechart = Notecharts:find({
		file_id = notechart_file.id,
		index = response_notechart.index,
	})

	local inputmode = Inputmodes[response_notechart.inputMode] and response_notechart.inputMode or "undefined"
	local inputmode_for_db = Inputmodes:for_db(inputmode)

	if not notechart then
		notechart = Notecharts:create({
			file_id = notechart_file.id,
			index = response_notechart.index,
			created_at = os.time(),
			is_complete = true,
			is_valid = true,
			scores_count = 0,
			inputmode = inputmode_for_db,
			difficulty = response_notechart.difficulty,
			song_title = response_notechart.title,
			song_artist = response_notechart.artist,
			difficulty_name = response_notechart.name,
			difficulty_creator = response_notechart.creator,
			level = response_notechart.level,
			length = response_notechart.length,
			notes_count = response_notechart.noteCount,
		})
		return notechart
	end

	notechart.is_complete = true
	notechart.is_valid = true
	notechart.inputmode = inputmode_for_db
	notechart.difficulty = response_notechart.difficulty
	notechart.song_title = response_notechart.title
	notechart.song_artist = response_notechart.artist
	notechart.difficulty_name = response_notechart.name
	notechart.difficulty_creator = response_notechart.creator
	notechart.level = response_notechart.level
	notechart.length = response_notechart.length
	notechart.notes_count = response_notechart.noteCount
	notechart:update(
		"is_complete",
		"is_valid",
		"inputmode",
		"difficulty",
		"song_title",
		"song_artist",
		"difficulty_name",
		"difficulty_creator",
		"level",
		"length",
		"notes_count"
	)

	return notechart
end

notechart_c.process_notechart = function(notechart)
	local notechart_file = notechart:get_file()
	notechart.file = nil
	if not notechart_file then
		notechart.is_complete = true
		notechart:update("is_complete")
		return false, 400, "not notechart_file"
	elseif not notechart_file.uploaded then
		return false, 400, "not notechart_file.uploaded"
	end

	local body, status_code, headers = http.simple({
		url = ("http://127.0.0.1:%d/notechart"):format(config.game_server_port),
		method = "POST",
		headers = {["content-type"] = "application/json"},
		body = to_json({notechart = {
			path = Files:get_path(notechart_file),
			extension = notechart_file.name:match("^.+%.(.-)$"),
			-- index = notechart.index,
		}})
	})

	if status_code == 502 then  -- Bad Gateway
		return false, 500, "Compute server is not available"
	end

	if status_code == 500 then  -- Internal Server Error
		notechart.is_complete = true
		notechart:update("is_complete")
		return false, 500, body
	end

	if status_code == 404 then
		return false, 404, "Notechart not found"
	end

	if status_code ~= 200 then
		return false, status_code, body
	end

	local json_response = from_json(body)
	local response_notecharts = json_response.notecharts
	local response_notechart

	for _, current_notechart in ipairs(response_notecharts) do
		local updated_notechart = notechart_c.set_notechart_from_metadata(notechart_file, current_notechart)
		if current_notechart.index == notechart.index then
			response_notechart = current_notechart
			notechart = updated_notechart
		end
	end

	notechart_file.loaded = true
	notechart_file:update("loaded")

	if not response_notechart then
		notechart.is_complete = true
		notechart:update("is_complete")
		return false, 400, "Invalid notechart"
	end

	return true
end

notechart_c.context.PATCH = {"notechart", "request_session", "session_user", "user_roles"}
notechart_c.policies.PATCH = {
	{"authed", {not_params = "force"}},
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
notechart_c.validations.PATCH = {
	{"force", type = "boolean", optional = true},
}
notechart_c.PATCH = function(self)
	local params = self.params
	local notechart = self.context.notechart

	if notechart.is_complete and not params.force then
		return {status = 204}
	end

	local success, code, message = notechart_c.process_notechart(notechart)
	if not success then
		return {status = code, json = {message = message}}
	end

	return {json = {notechart = notechart:to_name()}}
end

return notechart_c
