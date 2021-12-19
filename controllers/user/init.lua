local Users = require("models.users")
local Controller = require("Controller")

local user_c = Controller:new()

user_c.path = "/users/:user_id[%d]"
user_c.methods = {"GET", "PATCH", "DELETE"}
user_c.context = {"user", "user_roles"}
user_c.policies = {
	GET = require("policies.public"),
	PATCH = require("policies.public"),
	DELETE = require("policies.public"),
}

user_c.GET = function(request)
	local params = request.params
	local user = Users:find(params.user_id)

	return 200, {user = user and Users:safe_copy(user)}
end

user_c.PATCH = function(request)
	local params = request.params
	local user = Users:find(params.user_id)

	user.name = params.user.name
	user.description = params.user.description

	user:update("name", "description")

	return 200, {user = user}
end

user_c.DELETE = function(request)
	return 200, {}
end

return user_c
