local Group_users = require("models.group_users")
local User_roles = require("models.user_roles")
local preload = require("lapis.db.model").preload

local user_roles_c = {}

user_roles_c.GET = function(params)
    local roles = {}

    local user_roles = User_roles:find_all({params.user_id}, "user_id")
	preload(user_roles, "role", "domain")
	for _, user_role in ipairs(user_roles) do
		table.insert(roles, {
            role = user_role.role,
            domain = user_role.domain
        })
	end

	local group_users = Group_users:find_all({params.user_id}, "user_id")
	preload(group_users, {group = {group_roles = {"role", "domain"}}})
	for _, group_user in ipairs(group_users) do
		local group_roles = group_user.group.group_roles
		for _, group_role in ipairs(group_roles) do
            table.insert(roles, {
                role = group_role.role,
                domain = group_role.domain
            })
		end
	end

	return 200, {roles = roles}
end

return user_roles_c
