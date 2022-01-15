local Community_leaderboards = require("models.community_leaderboards")
local Controller = require("Controller")
local util = require("util")

local community_leaderboard_c = Controller:new()

community_leaderboard_c.path = "/communities/:community_id[%d]/leaderboards/:leaderboard_id[%d]"
community_leaderboard_c.methods = {"GET", "PUT", "DELETE", "PATCH"}

community_leaderboard_c.context.GET = {"community_leaderboard"}
community_leaderboard_c.policies.GET = {{"context_loaded"}}
community_leaderboard_c.validations.GET = util.add_belongs_to_validations(Community_leaderboards.relations)
community_leaderboard_c.GET = function(self)
	local community_leaderboard = self.context.community_leaderboard

	util.get_relatives(community_leaderboard, self.params, true)

	return {json = {community_leaderboard = community_leaderboard}}
end

community_leaderboard_c.context.PUT = {"community_leaderboard", "request_session"}
community_leaderboard_c.policies.PUT = {{"authenticated"}}
community_leaderboard_c.validations.PUT = {
	{"message", exists = true, type = "string"},
}
community_leaderboard_c.PUT = function(self)
	local params = self.params

	if self.context.community_leaderboard then
		return {}
	end

	local owner_community_leaderboard = Community_leaderboards:find({
		leaderboard_id = params.leaderboard_id,
		is_owner = true
	})
	local owner_community = owner_community_leaderboard:get_community()
	local community_leaderboard = Community_leaderboards:create({
		community_id = params.community_id,
		leaderboard_id = params.leaderboard_id,
		is_owner = false,
		user_id = self.session.user_id,
		accepted = owner_community.is_public,
		created_at = os.time(),
		message = params.message or "",
	})

	return {json = {community_leaderboard = community_leaderboard}}
end

community_leaderboard_c.context.DELETE = {"community_leaderboard", "request_session"}
community_leaderboard_c.policies.DELETE = {{"context_loaded", "authenticated"}}
community_leaderboard_c.DELETE = function(self)
	local community_leaderboard = self.context.community_leaderboard
    community_leaderboard:delete()

	return {status = 204}
end

community_leaderboard_c.context.PATCH = {"community_leaderboard", "request_session"}
community_leaderboard_c.policies.PATCH = {{"context_loaded", "authenticated"}}
community_leaderboard_c.PATCH = function(self)
	local community_leaderboard = self.context.community_leaderboard

	community_leaderboard.accepted = true
	community_leaderboard:update("accepted")

	return {json = {community_leaderboard = community_leaderboard}}
end

return community_leaderboard_c
