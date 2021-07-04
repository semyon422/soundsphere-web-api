local community_leaderboards = require("models.community_leaderboards")
local preload = require("lapis.db.model").preload

local community_leaderboards_c = {}

community_leaderboards_c.GET = function(params)
    local sub_community_leaderboards = community_leaderboards:find_all({params.community_id}, "community_id")
	preload(sub_community_leaderboards, "leaderboard")

	local leaderboards = {}
	for _, community_leaderboard in ipairs(sub_community_leaderboards) do
		local leaderboard = community_leaderboard.leaderboard
		table.insert(leaderboards, {
			id = leaderboard.id,
			name = leaderboard.name,
			description = leaderboard.description,
		})
	end

	local count = community_leaderboards:count()

	return 200, {
		total = count,
		filtered = count,
		leaderboards = leaderboards
	}
end

return community_leaderboards_c
