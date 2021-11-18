local Community_leaderboards = require("models.community_leaderboards")

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
    local community_leaderboard = {
        community_id = params.community_id,
        leaderboard_id = params.leaderboard_id,
    }
    if not Community_leaderboards:find(community_leaderboard) then
        Community_leaderboards:create(community_leaderboard)
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
