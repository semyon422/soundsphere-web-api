local Tables = require("models.tables")

local tables_c = {}

tables_c.path = "/tables"
tables_c.methods = {"GET", "POST"}
tables_c.context = {}
tables_c.policies = {
	GET = require("policies.public"),
	POST = require("policies.public"),
}

tables_c.GET = function(request)
	local params = request.params
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

tables_c.POST = function(request)
	local params = request.params
	local table_ = params.table
	table_ = Tables:create({
		name = table_.name,
		url = table_.url,
	})

	return 200, {table = table_}
end

return tables_c
