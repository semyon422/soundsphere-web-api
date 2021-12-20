local User_roles = require("models.user_roles")
local Roles = require("enums.roles")
local Controller = require("Controller")

local user_roles_c = Controller:new()

user_roles_c.path = "/users/:user_id[%d]/roles"
user_roles_c.methods = {"GET"}

user_roles_c.policies.GET = {{"permit"}}
user_roles_c.GET = function(request)
	local params = request.params
    local user_roles = User_roles:find_all({params.user_id}, "user_id")
    local roles = {}
	for _, user_role in ipairs(user_roles) do
		table.insert(roles, Roles:to_name(user_role.role))
	end

	return 200, {roles = roles}
end

return user_roles_c
