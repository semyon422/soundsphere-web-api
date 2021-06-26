local leaderboards = require("models.leaderboards")
local util = require("lapis.util")

local leaderboards_c = {}

leaderboards_c.GET = function(req, res, go)
	local per_page = req.query and tonumber(req.query.per_page) or 10
	local page_num = req.query and tonumber(req.query.page_num) or 1

	local paginator = leaderboards:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_leaderboard_entries = paginator:get_page(page_num)

	res.body = util.to_json({leaderboards = db_leaderboard_entries})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return leaderboards_c
