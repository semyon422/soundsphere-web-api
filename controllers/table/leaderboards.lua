local leaderboard_tables = require("models.leaderboard_tables")

local leaderboards_c = {}

leaderboards_c.GET = function(params)
	local db_leaderboard_entries = leaderboard_tables:find_all({params.table_id}, "table_id")

	return 200, {leaderboards = db_leaderboard_entries}
end

return leaderboards_c
