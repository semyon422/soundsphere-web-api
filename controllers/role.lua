local Roles = require("models.roles")

local role_c = {}

role_c.GET = function(params)
	local role = Roles:find(params.role_id)

	if role then
		return 200, {role = role}
	end

	return 404, {error = "Not found"}
end

return role_c
