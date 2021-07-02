local community_leaderboards = require("models.community_leaderboards")

local community_leaderboards_c = {}

community_leaderboards_c.PUT = function(params)
    local entry = {
        community_id = params.community_id,
        leaderboard_id = params.leaderboard_id,
    }
    local community_leaderboard = community_leaderboards:find(entry)
    if not community_leaderboard then
        community_leaderboards:create(entry)
    end

	return 200, {community_leaderboard = entry}
end

community_leaderboards_c.DELETE = function(params)
    local entry = {
        community_id = params.community_id,
        leaderboard_id = params.leaderboard_id,
    }
    local community_leaderboard = community_leaderboards:find(entry)
    if community_leaderboard then
        community_leaderboard:delete()
    end

	return 200, {}
end

return community_leaderboards_c
