local Community_leaderboards = require("models.community_leaderboards")
local Communities = require("models.communities")

local community_leaderboard_c = {}

community_leaderboard_c.path = "/communities/:community_id/leaderboards/:leaderboard_id"
community_leaderboard_c.methods = {"PUT", "DELETE"}
community_leaderboard_c.context = {"community", "leaderboard"}
community_leaderboard_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
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
		community_leaderboard.is_owner = false
		community_leaderboard.sender_id = request.session.user_id
		community_leaderboard.accepted = owner_community.is_public
		community_leaderboard.created_at = os.time()
		community_leaderboard.message = params.message or ""
        Community_leaderboards:create(community_leaderboard)
	else
		community_leaderboard.accepted = true
		community_leaderboard:update("accepted")
    end

	return 200, {}
end

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

return community_leaderboard_c
