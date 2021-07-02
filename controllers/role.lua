local roles = require("models.roles")

local role_c = {}

role_c.GET = function(params)
	local db_role_entry = roles:find(params.role_id)

	if db_role_entry then
		return 200, {role = db_role_entry}
	end

	return 404, {error = "Not found"}
end

return role_c
