local Group_users = require("models.group_users")

local group_users_c = {}

group_users_c.GET = function(params)
    local group_users = Group_users:find_all({params.group_id}, "group_id")

	return 200, {users = group_users}
end

return group_users_c
