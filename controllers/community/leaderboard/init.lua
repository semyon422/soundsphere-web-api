local Community_leaderboards = require("models.community_leaderboards")
local Communities = require("models.communities")
local Controller = require("Controller")

local community_leaderboard_c = Controller:new()

community_leaderboard_c.path = "/communities/:community_id[%d]/leaderboards/:leaderboard_id[%d]"
community_leaderboard_c.methods = {"PUT", "DELETE", "PATCH"}

community_leaderboard_c.context.PUT = {"community_leaderboard", "request_session"}
community_leaderboard_c.policies.PUT = {{"authenticated"}}
community_leaderboard_c.validations.PUT = {
	{"message", exists = true, type = "string"},
}
community_leaderboard_c.PUT = function(request)
	local params = request.params

	local community_leaderboard = request.context.community_leaderboard
	if community_leaderboard then
		community_leaderboard.accepted = true
		community_leaderboard:update("accepted")
		return 200, {}
	end

	local owner_community_leaderboard = Community_leaderboards:find({
		leaderboard_id = params.leaderboard_id,
		is_owner = true
	})
	local owner_community = owner_community_leaderboard:get_community()
	community_leaderboard = Community_leaderboards:create({
		community_id = params.community_id,
		leaderboard_id = params.leaderboard_id,
		is_owner = false,
		sender_id = request.session.user_id,
		accepted = owner_community.is_public,
		created_at = os.time(),
		message = params.message or "",
	})

	return 200, {community_leaderboard = community_leaderboard}
end

community_leaderboard_c.context.DELETE = {"community_leaderboard"}
community_leaderboard_c.policies.DELETE = {{"context_loaded"}}
community_leaderboard_c.DELETE = function(request)
	local community_leaderboard = request.context.community_leaderboard
    community_leaderboard:delete()

	return 200, {community_leaderboard = community_leaderboard}
end

community_leaderboard_c.context.PATCH = {"community_leaderboard"}
community_leaderboard_c.policies.PATCH = {{"context_loaded"}}
community_leaderboard_c.PATCH = function(request)
	local community_leaderboard = request.context.community_leaderboard

	community_leaderboard.accepted = true
	community_leaderboard:update("accepted")

	return 200, {community_leaderboard = community_leaderboard}
end

return community_leaderboard_c
