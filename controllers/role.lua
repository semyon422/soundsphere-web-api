local Roles = require("models.roles")

local role_c = {}

role_c.path = "/roles/:role_id"
role_c.methods = {"GET", "DELETE"}
role_c.context = {}
role_c.policies = {
	GET = require("policies.public"),
	DELETE = require("policies.public"),
}

role_c.GET = function(request)
	local params = request.params
	local role = Roles:find(params.role_id)

	return 200, {role = role}
end

role_c.DELETE = function(request)
	return 200, {}
end

return role_c
