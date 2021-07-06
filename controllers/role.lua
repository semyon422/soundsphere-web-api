local Roles = require("models.roles")

local role_c = {}

role_c.GET = function(params)
	local role = Roles:find(params.role_id)

	return 200, {role = role}
end

return role_c
