local Leaderboard_tables = require("models.leaderboard_tables")
local preload = require("lapis.db.model").preload

local leaderboards_c = {}

leaderboards_c.GET = function(params)
	local leaderboard_tables = Leaderboard_tables:find_all({params.table_id}, "table_id")
	preload(leaderboard_tables, "leaderboards")

	local leaderboards = {}
	for _, leaderboard_table in ipairs(leaderboard_tables) do
		table.insert(leaderboards, leaderboard_table.leaderboard)
	end

	local count = Leaderboard_tables:count()

	return 200, {
		total = count,
		filtered = count,
		leaderboards = leaderboards
	}
end

return leaderboards_c