local Users = require("models.users")
local Controller = require("Controller")

local user_c = Controller:new()

user_c.path = "/users/:user_id[%d]"
user_c.methods = {"GET", "PATCH", "DELETE"}

user_c.context.GET = {"user"}
user_c.policies.GET = {{"context_loaded"}}
user_c.GET = function(request)
	return 200, {user = request.context.user:to_name()}
end

user_c.context.PATCH = {"user", "request_session"}
user_c.policies.PATCH = {{"context_loaded", "authenticated"}}
user_c.validations.PATCH = {
	{"user", type = "table", param_type = "body", validations = {
		{"name", type = "string"},
		{"description", type = "string"},
	}},
}
user_c.PATCH = function(request)
	local params = request.params
	local user = request.context.user

	user.name = params.user.name
	user.description = params.user.description

	user:update("name", "description")

	return 200, {user = user:to_name()}
end

user_c.policies.DELETE = {{"permit"}}
user_c.DELETE = function(request)
	return 200, {}
end

return user_c
