local User_roles = require("models.user_roles")
local Roles = require("enums.roles")
local Controller = require("Controller")

local user_role_c = Controller:new()

user_role_c.path = "/users/:user_id[%d]/roles/:role"
user_role_c.methods = {"GET", "PUT", "DELETE"}
user_role_c.validations.path = {
	{"role", type = "string", one_of = Roles.list, param_type = "path"},
}

user_role_c.context.GET = {"user_role", "request_session"}
user_role_c.policies.GET = {{"authenticated"}}
user_role_c.GET = function(self)
	return {json = {user_role = self.context.user_role:to_name()}}
end

user_role_c.context.PUT = {
	{"user_role", missing = true},
	"request_session",
	"user",
	"session_user",
	"user_roles",
}
user_role_c.policies.PUT = {{"authenticated", "change_role"}}
user_role_c.PUT = function(self)
	local params = self.params

    local user_role = User_roles:create({
		user_id = params.user_id,
		role = Roles:for_db(params.role),
	})

	return {json = {user_role = user_role:to_name()}}
end

user_role_c.context.DELETE = {"user_role", "request_session", "user", "session_user", "user_roles"}
user_role_c.policies.DELETE = {{"authenticated", "context_loaded", "change_role"}}
user_role_c.DELETE = function(self)
    local user_role = self.context.user_role
    user_role:delete()

	return {status = 204}
end

return user_role_c
