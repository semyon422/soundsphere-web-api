local group_users = require("models.group_users")
local preload = require("lapis.db.model").preload

local user_groups_c = {}

user_groups_c.GET = function(params)
    local sub_group_users = group_users:find_all({params.user_id}, "user_id")
	preload(sub_group_users, "group")

    local groups = {}
	for _, group_user in ipairs(sub_group_users) do
        table.insert(groups, group_user.group)
	end

	return 200, {groups = groups}
end

return user_groups_c
