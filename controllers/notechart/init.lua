local Notecharts = require("models.notecharts")
local Files = require("models.files")
local Formats = require("enums.formats")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")
local add_belongs_to_validations = require("util.add_belongs_to_validations")
local get_relatives = require("util.get_relatives")
local http = require("lapis.nginx.http")
local util = require("lapis.util")
local to_json = util.to_json
local from_json = util.from_json

local notechart_c = Controller:new()

notechart_c.path = "/notecharts/:notechart_id[%d]"
notechart_c.methods = {"GET", "PATCH"}

notechart_c.context.GET = {"notechart"}
notechart_c.policies.GET = {{"context_loaded"}}
notechart_c.validations.GET = add_belongs_to_validations(Notecharts.relations)
notechart_c.GET = function(self)
	local notechart = self.context.notechart

	get_relatives(notechart, self.params, true)

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

	notechart.is_valid = true
	notechart.inputmode = Inputmodes:for_db(response_notechart.inputMode)
	-- notechart.difficulty = response_notechart.difficulty
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
