local notecharts = require("models.notecharts")
local util = require("lapis.util")

local notecharts_c = {}

notecharts_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = notecharts:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_notechart_entries = paginator:get_page(page_num)

	return 200, {notecharts = db_notechart_entries}
end

return notecharts_c
