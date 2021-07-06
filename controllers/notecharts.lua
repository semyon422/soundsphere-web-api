local Notecharts = require("models.notecharts")

local notecharts_c = {}

notecharts_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = Notecharts:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local notecharts = paginator:get_page(page_num)

	local count = Notecharts:count()

	return 200, {
		total = count,
		filtered = count,
		notecharts = notecharts
	}
end

return notecharts_c
