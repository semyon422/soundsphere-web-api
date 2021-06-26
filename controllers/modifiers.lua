local modifiers = require("models.modifiers")
local util = require("lapis.util")

local modifiers_c = {}

modifiers_c.GET = function(req, res, go)
	local per_page = req.query and tonumber(req.query.per_page) or 10
	local page_num = req.query and tonumber(req.query.page_num) or 1

	local paginator = modifiers:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_modifier_entries = paginator:get_page(page_num)

	res.body = util.to_json({modifiers = db_modifier_entries})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return modifiers_c
