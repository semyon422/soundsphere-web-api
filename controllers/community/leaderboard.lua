local Community_leaderboards = require("models.community_leaderboards")

local community_leaderboard_c = {}

community_leaderboard_c.PUT = function(params)
    local community_leaderboard = {
        community_id = params.community_id,
        leaderboard_id = params.leaderboard_id,
    }
    if not Community_leaderboards:find(community_leaderboard) then
        Community_leaderboards:create(community_leaderboard)
    end

	return 200, {}
end

community_leaderboard_c.DELETE = function(params)
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
