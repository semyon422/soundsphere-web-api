local groups = require("models.groups")
local util = require("lapis.util")

local groups_c = {}

groups_c.GET = function(req, res, go)
	local per_page = req.query and tonumber(req.query.per_page) or 10
	local page_num = req.query and tonumber(req.query.page_num) or 1

	local paginator = groups:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_group_entries = paginator:get_page(page_num)

	res.body = util.to_json({groups = db_group_entries})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return groups_c
