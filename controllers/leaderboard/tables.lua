local Leaderboard_tables = require("models.leaderboard_tables")
local preload = require("lapis.db.model").preload

local leaderboard_tables_c = {}

leaderboard_tables_c.GET = function(params)
    local leaderboard_tables = Leaderboard_tables:find_all({params.leaderboard_id}, "leaderboard_id")
	preload(leaderboard_tables, "leaderboard", "table")

	local count = Leaderboard_tables:count()

	return 200, {
		total = count,
		filtered = count,
		tables = leaderboard_tables
	}
end

return leaderboard_tables_c
