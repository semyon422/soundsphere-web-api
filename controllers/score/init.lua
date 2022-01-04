local Scores = require("models.scores")
local Files = require("models.files")
local Controller = require("Controller")
local add_belongs_to_validations = require("util.add_belongs_to_validations")
local get_relatives = require("util.get_relatives")

local score_c = Controller:new()

score_c.path = "/scores/:score_id[%d]"
score_c.methods = {"GET", "PATCH", "DELETE"}

score_c.load_replay = function(score)
	local replay_file = score:get_file()
	local content = Files:read_file(replay_file)

	return {json = {replay_file = #content}}
end

score_c.context.GET = {"score"}
score_c.policies.GET = {{"context_loaded"}}
score_c.validations.GET = add_belongs_to_validations(Scores.relations)
score_c.GET = function(self)
	local score = self.context.score

	get_relatives(score, self.params, true)

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
