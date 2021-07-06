local Community_leaderboards = require("models.community_leaderboards")

local community_leaderboards_c = {}

community_leaderboards_c.PUT = function(params)
    local community_leaderboard = {
        community_id = params.community_id,
        leaderboard_id = params.leaderboard_id,
    }
    community_leaderboard = Community_leaderboards:find(community_leaderboard)
    if not community_leaderboard then
        Community_leaderboards:create(community_leaderboard)
    end

	return 200, {community_leaderboard = community_leaderboard}
end

community_leaderboards_c.DELETE = function(params)
    local community_leaderboard = {
        community_id = params.community_id,
        leaderboard_id = params.leaderboard_id,
    }
    community_leaderboard = Community_leaderboards:find(community_leaderboard)
    if community_leaderboard then
        community_leaderboard:delete()
    end

	return 200, {}
end

return community_leaderboards_c
