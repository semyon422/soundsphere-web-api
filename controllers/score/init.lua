local Scores = require("models.scores")
local Files = require("models.files")
local Modifiersets = require("models.modifiersets")
local Controller = require("Controller")
local Formats = require("enums.formats")
local Inputmodes = require("enums.inputmodes")
local util = require("util")
local http = require("lapis.nginx.http")
local lapis_util = require("lapis.util")
local to_json = lapis_util.to_json
local from_json = lapis_util.from_json

local additions = {
	leaderboards = require("controllers.score.leaderboards"),
}

local score_c = Controller:new()

score_c.path = "/scores/:score_id[%d]"
score_c.methods = {"GET", "PATCH", "DELETE"}

score_c.load_replay = function(score)
	local replay_file = score:get_file()
	local notechart = score:get_notechart()
	local notechart_file = notechart:get_file()

	local body, status_code, headers = http.simple({
		url = "http://127.0.0.1:8082/replay",
		method = "POST",
		headers = {["content-type"] = "application/json"},
		body = to_json({
			notechart = {
				path = Files:get_path(notechart_file),
				extension = Formats:get_extension(notechart_file.format),
				index = notechart.index,
			},
			replay = {
				path = Files:get_path(replay_file)
			},
		})
	})

	if status_code ~= 200 then
		return {status = status_code, body}
	end

	local json_response = from_json(body)
	local response_score = json_response.score

	local new_modifierset = {
		encoded = json_response.modifiersEncoded,
		displayed = json_response.modifiersString,
	}
	local modifierset = Modifiersets:find(new_modifierset)
	if not modifierset then
		modifierset = Modifiersets:create(new_modifierset)
	end

	replay_file.loaded = true
	replay_file:update("loaded")

	score.modifierset_id = modifierset.id
	score.inputmode = Inputmodes:for_db(json_response.inputMode)
	score.is_valid = true
	score.score = response_score.normalscore.scoreAdjusted
	score.accuracy = response_score.normalscore.accuracyAdjusted
	score.max_combo = response_score.base.maxCombo
	score.performance = response_score.normalscore.rating32
	score:update(
		"modifierset_id",
		"inputmode",
		"is_valid",
		"score",
		"accuracy",
		"max_combo",
		"performance"
	)
	score.file = nil
	score.notechart = nil
	score.modifierset = modifierset

	return {json = {score = score:to_name()}}
end

score_c.context.GET = {"score"}
score_c.policies.GET = {{"context_loaded"}}
score_c.validations.GET = {}
util.add_additions_validations(additions, score_c.validations.GET)
util.add_belongs_to_validations(Scores.relations, score_c.validations.GET)
score_c.GET = function(self)
	local score = self.context.score

	util.load_additions(self, score, additions)
	util.get_relatives(score, self.params, true)

	return {json = {score = score:to_name()}}
end

score_c.context.PATCH = {"score"}
score_c.policies.PATCH = {{"context_loaded"}}
score_c.validations.PATCH = {
	{"load_replay", type = "boolean", optional = true},
}
score_c.PATCH = function(self)
	local params = self.params
	local score = self.context.score

	if params.load_replay then
		return score_c.load_replay(score)
	end

	return {}
end

score_c.context.DELETE = {"score"}
score_c.policies.DELETE = {{"context_loaded"}}
score_c.DELETE = function(self)
	return {status = 204}
end

return score_c
