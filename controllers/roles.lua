local Roles = require("models.roles")

local roles_c = {}

roles_c.path = "/roles"
roles_c.methods = {"GET", "POST", "DELETE"}
roles_c.context = {}
roles_c.policies = {
	GET = require("policies.public"),
	POST = require("policies.public"),
	DELETE = require("policies.public"),
}

roles_c.GET = function(request)
	local params = request.params
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

roles_c.POST = function(request)
	local params = request.params
	local role = Roles:assign(params.roletype, params)

	return 200, {role = role}
end

roles_c.DELETE = function(request)
	local params = request.params
	local role = Roles:reject(params.roletype, params)

	return 200, {role = role}
end

return roles_c
