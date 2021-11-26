local User_roles = require("models.user_roles")
local Roles = require("enums.roles")

local user_role_c = {}

user_role_c.path = "/users/:user_id/roles/:role"
user_role_c.methods = {"PUT", "DELETE"}
user_role_c.context = {}
user_role_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
}

user_role_c.PUT = function(request)
	local params = request.params
    local user_role = {
        user_id = params.user_id,
        role = Roles:for_db(params.role),
    }
    if not User_roles:find(user_role) then
        User_roles:create(user_role)
    end

	return 200, {}
end

user_role_c.DELETE = function(request)
	local params = request.params
    local user_role = User_roles:find({
        user_id = params.user_id,
        role = Roles:for_db(params.role),
    })
    if user_role then
        user_role:delete()
    end

	return 200, {}
end

return user_role_c
