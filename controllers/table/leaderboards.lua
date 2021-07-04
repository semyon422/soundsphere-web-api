local leaderboard_tables = require("models.leaderboard_tables")

local leaderboards_c = {}

leaderboards_c.GET = function(params)
	local db_leaderboard_entries = leaderboard_tables:find_all({params.table_id}, "table_id")

	local count = leaderboard_tables:count()

	return 200, {
		total = count,
		filtered = count,
		leaderboards = db_leaderboard_entries
	}
end

return leaderboards_c
