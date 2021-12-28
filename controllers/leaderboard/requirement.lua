local Leaderboard_requirements = require("models.leaderboard_requirements")
local Requirements = require("enums.requirements")
local Rules = require("enums.rules")
local Controller = require("Controller")

local leaderboard_requirement_c = Controller:new()

leaderboard_requirement_c.path = "/leaderboards/:leaderboard_id[%d]/requirements/:requirement_id[%d]"
leaderboard_requirement_c.methods = {"GET", "PATCH", "DELETE"}

leaderboard_requirement_c.context.GET = {"leaderboard_requirement", "request_session"}
leaderboard_requirement_c.policies.GET = {{"authenticated", "context_loaded"}}
leaderboard_requirement_c.GET = function(request)
	local params = request.params

    local requirement = request.context.leaderboard_requirement
	requirement.name = Requirements:to_name(requirement.requirement)
	requirement.rule = Rules:to_name(requirement.rule)
	requirement.key = Requirements:get_key_enum(requirement.requirement):to_name(requirement.key)
	requirement.requirement = nil

	return 200, {requirement = requirement}
end

leaderboard_requirement_c.context.PATCH = {"leaderboard_requirement", "request_session"}
leaderboard_requirement_c.policies.PATCH = {{"authenticated", "context_loaded"}}
leaderboard_requirement_c.validations.PATCH = {
	{"requirement", exists = true, type = "table", body = true, validations = {
		{"name", exists = true, type = "string", one_of = Requirements.list},
		{"rule", exists = true, type = "string", one_of = Rules.list},
		{"key", exists = true, type = "string"},
		{"value", exists = true, type = "string"},
	}}
}
leaderboard_requirement_c.PATCH = function(request)
	local params = request.params

    local requirement = request.context.leaderboard_requirement
	local params_requirement = params.requirement

	requirement.requirement = Requirements:for_db(params_requirement.name)
	requirement.rule = Rules:for_db(params_requirement.rule)
	requirement.key = Requirements:get_key_enum(params_requirement.name):for_db(params_requirement.key)
	requirement.value = params_requirement.value
    requirement:update("requirement", "rule", "key", "value")

	requirement.name = Requirements:to_name(requirement.requirement)
	requirement.rule = Rules:to_name(requirement.rule)
	requirement.key = Requirements:get_key_enum(requirement.requirement):to_name(requirement.key)
	requirement.requirement = nil

	return 200, {requirement = requirement}
end

leaderboard_requirement_c.context.DELETE = {"leaderboard_requirement", "request_session"}
leaderboard_requirement_c.policies.DELETE = {{"authenticated", "context_loaded"}}
leaderboard_requirement_c.DELETE = function(request)
    local requirement = request.context.leaderboard_requirement
    requirement:delete()

	return 200, {requirement = requirement}
end

return leaderboard_requirement_c
