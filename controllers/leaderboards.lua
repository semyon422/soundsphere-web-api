local leaderboards = require("models.leaderboards")
local util = require("lapis.util")

local leaderboards_c = {}

leaderboards_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = leaderboards:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_leaderboard_entries = paginator:get_page(page_num)

	return 200, {leaderboards = db_leaderboard_entries}
end

return leaderboards_c
