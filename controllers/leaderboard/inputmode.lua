local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")
local util = require("util")

local leaderboard_inputmode_c = Controller:new()

leaderboard_inputmode_c.path = "/leaderboards/:leaderboard_id[%d]/inputmodes/:inputmode"
leaderboard_inputmode_c.methods = {"GET", "PUT", "DELETE"}
leaderboard_inputmode_c.validations.path = {
	{"inputmode", type = "string", one_of = Inputmodes.list, param_type = "path"},
}

leaderboard_inputmode_c.context.GET = {"leaderboard_inputmode"}
leaderboard_inputmode_c.policies.GET = {{"permit"}}
leaderboard_inputmode_c.GET = function(self)
	return {json = {leaderboard_inputmode = self.context.leaderboard_inputmode:to_name()}}
end

leaderboard_inputmode_c.context.PUT = {
	{"leaderboard_inputmode", missing = true},
	"leaderboard",
	"request_session",
	"session_user",
	"user_communities",
}
leaderboard_inputmode_c.policies.PUT = {
	{"authed", {leaderboard_role = "moderator"}},
	{"authed", {leaderboard_role = "admin"}},
	{"authed", {leaderboard_role = "creator"}},
}
leaderboard_inputmode_c.PUT = function(self)
	local params = self.params

    local leaderboard_inputmode = Leaderboard_inputmodes:create({
		leaderboard_id = params.leaderboard_id,
		inputmode = Inputmodes:for_db(params.inputmode),
	})

	return {json = {leaderboard_inputmode = leaderboard_inputmode:to_name()}}
end

leaderboard_inputmode_c.context.DELETE = {
	"leaderboard_inputmode",
	"leaderboard",
	"request_session",
	"session_user",
	"user_communities"
}
leaderboard_inputmode_c.policies.DELETE = {
	{"authed", {leaderboard_role = "moderator"}},
	{"authed", {leaderboard_role = "admin"}},
	{"authed", {leaderboard_role = "creator"}},
}
leaderboard_inputmode_c.DELETE = function(self)
    local leaderboard_inputmode = self.context.leaderboard_inputmode
    leaderboard_inputmode:delete()

	return {status = 204}
end

return leaderboard_inputmode_c
