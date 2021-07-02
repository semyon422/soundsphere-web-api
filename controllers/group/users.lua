local group_users = require("models.group_users")

local group_users_c = {}

group_users_c.GET = function(params)
    local sub_group_users = group_users:find_all({params.group_id}, "group_id")

	return 200, {users = sub_group_users}
end

return group_users_c
