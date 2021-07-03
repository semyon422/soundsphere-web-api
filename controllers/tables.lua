local tables = require("models.tables")

local tables_c = {}

tables_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = tables:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_table_entries = paginator:get_page(page_num)

	local count = tables:count()

	return 200, {
		total = count,
		filtered = count,
		tables = db_table_entries
	}
end

return tables_c
