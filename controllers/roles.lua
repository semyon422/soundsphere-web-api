local Roles = require("models.roles")

local roles_c = {}

roles_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = Roles:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local roles = paginator:get_page(page_num)

	local count = Roles:count()

	return 200, {
		total = count,
		filtered = count,
		roles = roles
	}
end

roles_c.POST = function(params)
	local role = Roles:assign(params.roletype, params)

	return 200, {role = role}
end

roles_c.DELETE = function(params)
	Roles:reject(params.roletype, params)

	return 200, {}
end

return roles_c
