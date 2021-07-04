local leaderboard_tables = require("models.leaderboard_tables")
local preload = require("lapis.db.model").preload

local leaderboard_tables_c = {}

leaderboard_tables_c.GET = function(params)
    local sub_leaderboard_tables = leaderboard_tables:find_all({params.leaderboard_id}, "leaderboard_id")
	preload(sub_leaderboard_tables, "leaderboard", "table")

	local count = leaderboard_tables:count()

	return 200, {
		total = count,
		filtered = count,
		tables = sub_leaderboard_tables
	}
end

return leaderboard_tables_c
