local Group_users = require("models.group_users")

local group_users_c = {}

group_users_c.path = "/groups/:group_id/users"
group_users_c.methods = {"PUT", "DELETE"}
group_users_c.context = {"group", "user", "user_roles"}
group_users_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
}

group_users_c.GET = function(request)
	local params = request.params
    local group_users = Group_users:find_all({params.group_id}, "group_id")

	return 200, {users = group_users}
end

return group_users_c
