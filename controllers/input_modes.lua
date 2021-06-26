local input_modes = require("models.input_modes")
local util = require("lapis.util")

local input_modes_c = {}

input_modes_c.GET = function(req, res, go)
	local per_page = req.query and tonumber(req.query.per_page) or 10
	local page_num = req.query and tonumber(req.query.page_num) or 1

	local paginator = input_modes:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_input_mode_entries = paginator:get_page(page_num)

	res.body = util.to_json({input_modes = db_input_mode_entries})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return input_modes_c
