local Leaderboard_difftables = require("models.leaderboard_difftables")
local Controller = require("Controller")
local util = require("util")

local leaderboard_difftable_c = Controller:new()

leaderboard_difftable_c.path = "/leaderboards/:leaderboard_id[%d]/difftables/:difftable_id[%d]"
leaderboard_difftable_c.methods = {"GET", "PUT", "DELETE"}

leaderboard_difftable_c.context.GET = {"leaderboard_difftable"}
leaderboard_difftable_c.policies.GET = {{"permit"}}
leaderboard_difftable_c.GET = function(self)
	return {json = {leaderboard_difftable = self.context.leaderboard_difftable}}
end

leaderboard_difftable_c.context.PUT = {
	{"leaderboard_difftable", missing = true},
	"leaderboard",
	"request_session",
	"session_user",
	"user_communities",
}
leaderboard_difftable_c.policies.PUT = {
	{"authed", {leaderboard_role = "moderator"}},
	{"authed", {leaderboard_role = "admin"}},
	{"authed", {leaderboard_role = "creator"}},
}
leaderboard_difftable_c.PUT = function(self)
	local params = self.params

    local leaderboard_difftable = Leaderboard_difftables:create({
		leaderboard_id = params.leaderboard_id,
		difftable_id = params.difftable_id,
	})

	return {json = {leaderboard_difftable = leaderboard_difftable}}
end

leaderboard_difftable_c.context.DELETE = {
	"leaderboard_difftable",
	"leaderboard",
	"request_session",
	"session_user",
	"user_communities"
}
leaderboard_difftable_c.policies.DELETE = {
	{"authed", {leaderboard_role = "moderator"}},
	{"authed", {leaderboard_role = "admin"}},
	{"authed", {leaderboard_role = "creator"}},
}
leaderboard_difftable_c.DELETE = function(self)
    local leaderboard_difftable = self.context.leaderboard_difftable
    leaderboard_difftable:delete()

	return {status = 204}
end

return leaderboard_difftable_c
