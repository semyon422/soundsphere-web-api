local Roles = require("models.roles")

local role_c = {}

role_c.GET = function(request)
	local params = request.params
	local role = Roles:find(params.role_id)

	return 200, {role = role}
end

return role_c
