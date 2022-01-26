local User_roles = require("models.user_roles")
local Controller = require("Controller")
local util = require("util")

local user_roles_c = Controller:new()

user_roles_c.path = "/users/:user_id[%d]/roles"
user_roles_c.methods = {"GET"}

user_roles_c.policies.GET = {{"permit"}}
user_roles_c.GET = function(self)
	local params = self.params
    local user_roles = User_roles:find_all({params.user_id}, "user_id")

	if params.no_data then
		return {json = {
			total = #user_roles,
			filtered = #user_roles,
		}}
	end

	for _, user_role in ipairs(user_roles) do
		user_role.is_expired = user_role.expires_at <= os.time()
	end
	util.recursive_to_name(user_roles)

	return {json = {user_roles = user_roles}}
end

return user_roles_c
