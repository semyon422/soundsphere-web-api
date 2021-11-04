local Community_leaderboards = require("models.community_leaderboards")
local preload = require("lapis.db.model").preload

local community_leaderboards_c = {}

community_leaderboards_c.GET = function(request)
	local params = request.params
    local community_leaderboards = Community_leaderboards:find_all({params.community_id}, "community_id")
	preload(community_leaderboards, "leaderboard")

	local leaderboards = {}
	for _, community_leaderboard in ipairs(community_leaderboards) do
		table.insert(leaderboards, community_leaderboard.leaderboard)
	end

	local count = Community_leaderboards:count()

	return 200, {
		total = count,
		filtered = count,
		leaderboards = leaderboards
	}
end

return community_leaderboards_c
