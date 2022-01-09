local Leaderboard_requirements = require("models.leaderboard_requirements")
local Requirements = require("enums.requirements")
local Rules = require("enums.rules")
local Controller = require("Controller")

local leaderboard_requirement_c = Controller:new()

leaderboard_requirement_c.path = "/leaderboards/:leaderboard_id[%d]/requirements/:requirement_id[%d]"
leaderboard_requirement_c.methods = {"GET", "PATCH", "DELETE"}

leaderboard_requirement_c.context.GET = {"leaderboard_requirement", "request_session"}
leaderboard_requirement_c.policies.GET = {{"authenticated", "context_loaded"}}
leaderboard_requirement_c.GET = function(self)
    local leaderboard_requirement = self.context.leaderboard_requirement

	return {json = {leaderboard_requirement = leaderboard_requirement:to_name()}}
end

leaderboard_requirement_c.context.PATCH = {"leaderboard_requirement", "request_session"}
leaderboard_requirement_c.policies.PATCH = {{"authenticated", "context_loaded"}}
leaderboard_requirement_c.validations.PATCH = {
	{"requirement", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string", one_of = Requirements.list},
		{"rule", exists = true, type = "string", one_of = Rules.list},
		{"key", exists = true, type = "string"},
		{"value", exists = true, type = "string"},
	}}
}
leaderboard_requirement_c.PATCH = function(self)
	local params = self.params

    local requirement = self.context.leaderboard_requirement
	local params_requirement = params.requirement

	requirement.name = params_requirement.name
	requirement.rule = params_requirement.rule
	requirement.key = params_requirement.key
	requirement.value = params_requirement.value

	requirement:for_db()
    requirement:update("requirement", "rule", "key", "value")

	return {json = {requirement = requirement:to_name()}}
end

leaderboard_requirement_c.context.DELETE = {"leaderboard_requirement", "request_session"}
leaderboard_requirement_c.policies.DELETE = {{"authenticated", "context_loaded"}}
leaderboard_requirement_c.DELETE = function(self)
    local requirement = self.context.leaderboard_requirement
    requirement:delete()

	return {status = 204}
end

return leaderboard_requirement_c
