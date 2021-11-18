local Roles = require("models.roles")

local user_roles_c = {}

user_roles_c.path = "/users/:user_id/roles"
user_roles_c.methods = {"GET"}
user_roles_c.context = {}
user_roles_c.policies = {
	GET = require("policies.public"),
}

user_roles_c.GET = function(request)
	local params = request.params
    local roles = Roles:extract_list({user_id = params.user_id})

	return 200, {
		total = #roles,
		filtered = #roles,
		roles = roles
	}
end

return user_roles_c
