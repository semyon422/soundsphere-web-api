local Community_leaderboards = require("models.community_leaderboards")
local preload = require("lapis.db.model").preload

local leaderboard_communities_c = {}

leaderboard_communities_c.path = "/leaderboards/:leaderboard_id/communities"
leaderboard_communities_c.methods = {"GET"}
leaderboard_communities_c.context = {}
leaderboard_communities_c.policies = {
	GET = require("policies.public"),
}

leaderboard_communities_c.GET = function(request)
	local params = request.params
    local leaderboard_communities = Community_leaderboards:find_all({params.leaderboard_id}, "leaderboard_id")
	preload(leaderboard_communities, "leaderboard", "community")

	local communities = {}
	for _, community_leaderboard in ipairs(leaderboard_communities) do
		table.insert(communities, community_leaderboard.community)
	end

	local count = #communities

	return 200, {
		total = count,
		filtered = count,
		communities = communities
	}
end

return leaderboard_communities_c
