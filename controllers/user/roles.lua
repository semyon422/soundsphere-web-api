local Roles = require("models.roles")

local user_roles_c = {}

user_roles_c.GET = function(params)
    local roles = Roles:extract_list({user_id = params.user_id})

	local count = Roles:count()

	return 200, {
		total = count,
		filtered = count,
		roles = roles
	}
end

return user_roles_c
