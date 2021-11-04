local Roles = require("models.roles")

local group_roles_c = {}

group_roles_c.GET = function(request)
	local params = request.params
    local roles = Roles:extract_list({group_id = params.group_id})

	return 200, {roles = roles}
end

return group_roles_c
