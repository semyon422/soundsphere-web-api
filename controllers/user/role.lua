local User_roles = require("models.user_roles")
local Roles = require("enums.roles")
local Controller = require("Controller")

local user_role_c = Controller:new()

user_role_c.path = "/users/:user_id[%d]/roles/:role"
user_role_c.methods = {"PUT", "DELETE"}
user_role_c.validations.path = {
	{"role", type = "string", one_of = Roles.list, param_type = "path"},
}

user_role_c.context.PUT = {"user_role", "request_session"}
user_role_c.policies.PUT = {{"authenticated"}}
user_role_c.PUT = function(self)
	local params = self.params

    local user_role = self.context.user_role
    if not user_role then
        user_role = User_roles:create({
			user_id = params.user_id,
			role = Roles:for_db(params.role),
		})
    end

	return {json = {user_role = user_role:to_name()}}
end

user_role_c.context.DELETE = {"user_role", "request_session"}
user_role_c.policies.DELETE = {{"authenticated", "context_loaded"}}
user_role_c.DELETE = function(self)
    local user_role = self.context.user_role
    user_role:delete()

	return {status = 204}
end

return user_role_c
