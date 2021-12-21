local Community_leaderboards = require("models.community_leaderboards")
local Communities = require("models.communities")
local Controller = require("Controller")

local community_leaderboard_c = Controller:new()

community_leaderboard_c.path = "/communities/:community_id[%d]/leaderboards/:leaderboard_id[%d]"
community_leaderboard_c.methods = {"PUT", "DELETE", "PATCH"}

community_leaderboard_c.context.PUT = {"community", "leaderboard"}
community_leaderboard_c.policies.PUT = {{"permit"}}
community_leaderboard_c.validations.PUT = {
	{"message", exists = true, type = "string"},
}
community_leaderboard_c.PUT = function(request)
	local params = request.params

    local new_community_leaderboard = {
        community_id = params.community_id,
        leaderboard_id = params.leaderboard_id,
    }
	local community_leaderboard = Community_leaderboards:find(new_community_leaderboard)

	local owner_community_leaderboard = Community_leaderboards:find({
		leaderboard_id = params.leaderboard_id,
		is_owner = true
	})
	local owner_community = owner_community_leaderboard:get_community()

    if not community_leaderboard then
		new_community_leaderboard.is_owner = false
		new_community_leaderboard.sender_id = request.session.user_id
		new_community_leaderboard.accepted = owner_community.is_public
		new_community_leaderboard.created_at = os.time()
		new_community_leaderboard.message = params.message or ""
        Community_leaderboards:create(new_community_leaderboard)
	else
		community_leaderboard.accepted = true
		community_leaderboard:update("accepted")
    end

	return 200, {}
end

community_leaderboard_c.context.DELETE = {"community", "leaderboard"}
community_leaderboard_c.policies.DELETE = {{"permit"}}
community_leaderboard_c.DELETE = function(request)
	local params = request.params
    local community_leaderboard = Community_leaderboards:find({
        community_id = params.community_id,
        leaderboard_id = params.leaderboard_id,
    })
    if community_leaderboard then
        community_leaderboard:delete()
    end

	return 200, {}
end

community_leaderboard_c.context.PATCH = {"community", "leaderboard"}
community_leaderboard_c.policies.PATCH = {{"permit"}}
community_leaderboard_c.PATCH = function(request)
	local params = request.params

	local community_leaderboard = Community_leaderboards:find({
        community_id = params.community_id,
        leaderboard_id = params.leaderboard_id,
    })

	community_leaderboard.accepted = true
	community_leaderboard:update("accepted")

	return 200, {}
end

return community_leaderboard_c
