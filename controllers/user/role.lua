local User_roles = require("models.user_roles")
local Roles = require("enums.roles")
local Controller = require("Controller")

local user_role_c = Controller:new()

user_role_c.path = "/users/:user_id[%d]/roles/:role"
user_role_c.methods = {"GET", "PUT", "PATCH", "DELETE"}
user_role_c.validations.path = {
	{"role", type = "string", one_of = Roles.list, param_type = "path"},
}

user_role_c.context.GET = {"user_role", "request_session"}
user_role_c.policies.GET = {{"authed"}}
user_role_c.GET = function(self)
    local user_role = self.context.user_role
	user_role.is_expired = user_role.expires_at <= os.time()

	return {json = {user_role = user_role:to_name()}}
end

user_role_c.context.PUT = {
	{"user_role", missing = true},
	"request_session",
	"user",
	"session_user",
	"user_roles",
}
user_role_c.policies.PUT = {{"authed", "change_role"}}
user_role_c.validations.PUT = {
	{"expires_at", exists = true, type = "number"},
}
user_role_c.PUT = function(self)
	local params = self.params

    local user_role = User_roles:create({
		user_id = params.user_id,
		role = Roles:for_db(params.role),
		expires_at = params.expires_at,
	})
	user_role.is_expired = user_role.expires_at <= os.time()

	return {json = {user_role = user_role:to_name()}}
end

user_role_c.context.PATCH = {
	"user_role",
	"request_session",
	"user",
	"session_user",
	"user_roles",
}
user_role_c.policies.PATCH = {{"authed", "change_role"}}
user_role_c.validations.PATCH = {
	{"expires_at", exists = true, type = "number"},
}
user_role_c.PATCH = function(self)
	local params = self.params

	local user_role = self.context.user_role
	user_role.expires_at = params.expires_at
    user_role:update("expires_at")
	user_role.is_expired = user_role.expires_at <= os.time()

	return {json = {user_role = user_role:to_name()}}
end

user_role_c.context.DELETE = {"user_role", "request_session", "user", "session_user", "user_roles"}
user_role_c.policies.DELETE = {{"authed", "context_loaded", "change_role"}}
user_role_c.DELETE = function(self)
    local user_role = self.context.user_role
    user_role:delete()

	return {status = 204}
end

return user_role_c
