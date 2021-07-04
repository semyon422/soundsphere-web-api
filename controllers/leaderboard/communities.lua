local community_leaderboards = require("models.community_leaderboards")
local preload = require("lapis.db.model").preload

local leaderboard_communities_c = {}

leaderboard_communities_c.GET = function(params)
    local sub_leaderboard_communities = community_leaderboards:find_all({params.leaderboard_id}, "leaderboard_id")
	preload(sub_leaderboard_communities, "leaderboard", "community")

	local count = community_leaderboards:count()

	return 200, {
		total = count,
		filtered = count,
		communities = sub_leaderboard_communities
	}
end

return leaderboard_communities_c
