local Leaderboard_tables = require("models.leaderboard_tables")

local leaderboards_c = {}

leaderboards_c.GET = function(params)
	local leaderboard_tables = Leaderboard_tables:find_all({params.table_id}, "table_id")

	local count = Leaderboard_tables:count()

	return 200, {
		total = count,
		filtered = count,
		leaderboards = leaderboard_tables
	}
end

return leaderboards_c
