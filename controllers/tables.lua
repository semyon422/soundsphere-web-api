local Tables = require("models.tables")

local tables_c = {}

tables_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = Tables:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local tables = paginator:get_page(page_num)

	local count = Tables:count()

	return 200, {
		total = count,
		filtered = count,
		tables = tables
	}
end

return tables_c
