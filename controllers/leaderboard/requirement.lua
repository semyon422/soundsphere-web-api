local Leaderboard_requirements = require("models.leaderboard_requirements")
local Requirements = require("enums.requirements")
local Rules = require("enums.rules")
local Controller = require("Controller")
local util = require("util")

local leaderboard_requirement_c = Controller:new()

leaderboard_requirement_c.path = "/leaderboards/:leaderboard_id[%d]/requirements/:requirement_id[%d]"
leaderboard_requirement_c.methods = {"GET", "PATCH", "DELETE"}

leaderboard_requirement_c.context.GET = {"leaderboard_requirement"}
leaderboard_requirement_c.policies.GET = {{"permit"}}
leaderboard_requirement_c.GET = function(self)
    local leaderboard_requirement = self.context.leaderboard_requirement

	return {json = {leaderboard_requirement = leaderboard_requirement:to_name()}}
end

leaderboard_requirement_c.context.PATCH = {
	"leaderboard_requirement",
	"leaderboard",
	"request_session",
	"session_user",
	"user_communities"
}
leaderboard_requirement_c.policies.PATCH = {
	{"authed", {leaderboard_role = "moderator"}},
	{"authed", {leaderboard_role = "admin"}},
	{"authed", {leaderboard_role = "creator"}},
}
leaderboard_requirement_c.validations.PATCH = {
	{"leaderboard_requirement", type = "table", param_type = "body", validations = {
		{"name", type = "string", one_of = Requirements.list},
		{"rule", type = "string", one_of = Rules.list},
		{"key", type = "string"},
		{"value", type = "string"},
	}}
}
leaderboard_requirement_c.PATCH = function(self)
	local params = self.params

    local requirement = self.context.leaderboard_requirement

	Leaderboard_requirements:for_db(params.leaderboard_requirement)
	util.patch(requirement, params.leaderboard_requirement, {
		"requirement",
		"rule",
		"key",
		"value",
	})

	return {json = {leaderboard_requirement = requirement:to_name()}}
end

leaderboard_requirement_c.context.DELETE = leaderboard_requirement_c.context.PATCH
leaderboard_requirement_c.policies.DELETE = leaderboard_requirement_c.policies.PATCH
leaderboard_requirement_c.DELETE = function(self)
    local requirement = self.context.leaderboard_requirement
    requirement:delete()

	return {status = 204}
end

return leaderboard_requirement_c
