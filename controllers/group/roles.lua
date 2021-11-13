local Roles = require("models.roles")

local group_roles_c = {}

group_roles_c.path = "/groups/:group_id/roles"
group_roles_c.methods = {"GET"}
group_roles_c.context = {"group"}
group_roles_c.policies = {
	GET = require("policies.public"),
}

group_roles_c.GET = function(request)
	local params = request.params
    local roles = Roles:extract_list({group_id = params.group_id})

	return 200, {roles = roles}
end

return group_roles_c
