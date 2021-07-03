local roles = require("models.roles")

local roles_c = {}

roles_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = roles:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_role_entries = paginator:get_page(page_num)

	local count = roles:count()

	return 200, {
		total = count,
		filtered = count,
		roles = db_role_entries
	}
end

return roles_c
