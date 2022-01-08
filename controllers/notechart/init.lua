local Notecharts = require("models.notecharts")
local Files = require("models.files")
local Formats = require("enums.formats")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")
local util = require("util")
local http = require("lapis.nginx.http")
local lapis_util = require("lapis.util")
local to_json = lapis_util.to_json
local from_json = lapis_util.from_json

local additions = {
	notechart_scores = require("controllers.notechart.scores"),
}

local notechart_c = Controller:new()

notechart_c.path = "/notecharts/:notechart_id[%d]"
notechart_c.methods = {"GET", "PATCH"}

notechart_c.context.GET = {"notechart"}
notechart_c.policies.GET = {{"context_loaded"}}
util.add_additions_validations(additions, notechart_c.validations.GET)
util.add_belongs_to_validations(Notecharts.relations, notechart_c.validations.GET)
notechart_c.GET = function(self)
	local notechart = self.context.notechart

	util.load_additions(self, notechart, self.params, additions)
	util.get_relatives(notechart, self.params, true)

	return {json = {notechart = notechart:to_name()}}
end

notechart_c.context.PATCH = {"notechart"}
notechart_c.policies.PATCH = {{"context_loaded"}}
notechart_c.validations.PATCH = {
	{"load_file", type = "boolean", optional = true}
}
notechart_c.PATCH = function(self)
	local notechart = self.context.notechart
	local notechart_file = notechart:get_file()

	local body, status_code, headers = http.simple({
		url = "http://127.0.0.1:8082/notechart",
		method = "POST",
		headers = {["content-type"] = "application/json"},
		body = to_json({notechart = {
			path = Files:get_path(notechart_file),
			extension = Formats:get_extension(notechart_file.format),
			index = notechart.index,
		}})
	})

	if status_code ~= 200 then
		return {status = status_code, body}
	end

	local json_response = from_json(body)
	local response_notechart = json_response.notechart

	notechart_file.loaded = true
	notechart_file:update("loaded")

	notechart.is_valid = true
	notechart.inputmode = Inputmodes:for_db(response_notechart.inputMode)
	notechart.difficulty = response_notechart.difficulty
	notechart.song_title = response_notechart.title
	notechart.song_artist = response_notechart.artist
	notechart.difficulty_name = response_notechart.name
	notechart.difficulty_creator = response_notechart.creator
	notechart:update(
		"is_valid",
		"inputmode",
		"song_title",
		"song_artist",
		"difficulty_name",
		"difficulty_creator"
	)
	notechart.file = nil

	return {json = {notechart = notechart:to_name()}}
end

return notechart_c
