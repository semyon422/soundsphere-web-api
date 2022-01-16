local Leaderboard_users = require("models.leaderboard_users")
local Controller = require("Controller")
local util = require("util")

local leaderboard_user_c = Controller:new()

leaderboard_user_c.path = "/leaderboards/:leaderboard_id[%d]/users/:user_id[%d]"
leaderboard_user_c.methods = {"GET", "PATCH"}

leaderboard_user_c.context.GET = {"leaderboard_user", "request_session"}
leaderboard_user_c.policies.GET = {{"authenticated"}}
leaderboard_user_c.validations.GET = util.add_belongs_to_validations(Leaderboard_users.relations)
leaderboard_user_c.GET = function(self)
    local leaderboard_user = self.context.leaderboard_user

	return {json = {leaderboard_user = leaderboard_user}}
end

leaderboard_user_c.context.PATCH = {"leaderboard_user"}
util.get_owner_context("leaderboard", "context", leaderboard_user_c.context.PATCH)
leaderboard_user_c.policies.PATCH = {
	{"authenticated", {community_role = "moderator"}},
	{"authenticated", {community_role = "admin"}},
	{"authenticated", {community_role = "creator"}},
}
leaderboard_user_c.validations.PATCH = {
	{"active", type = "boolean", optional = true},
}
leaderboard_user_c.PATCH = function(self)
    local leaderboard_user = self.context.leaderboard_user

	leaderboard_user.active = self.params.active
    leaderboard_user:update("active")

	return {json = {leaderboard_user = leaderboard_user}}
end

return leaderboard_user_c
