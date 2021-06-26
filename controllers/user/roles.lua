local group_users = require("models.group_users")
local user_roles = require("models.user_roles")
local util = require("lapis.util")
local preload = require("lapis.db.model").preload

local user_roles_c = {}

user_roles_c.GET = function(req, res, go)
    local roles = {}

    local sub_user_roles = user_roles:find_all({req.params.user_id}, "user_id")
	preload(sub_user_roles, "role", "domain")
	for _, user_role in ipairs(sub_user_roles) do
		table.insert(roles, {
            role = user_role.role,
            domain = user_role.domain
        })
	end

	local sub_group_users = group_users:find_all({req.params.user_id}, "user_id")
	preload(sub_group_users, {group = {group_roles = {"role", "domain"}}})
	for _, group_user in ipairs(sub_group_users) do
		local group_roles = group_user.group.group_roles
		for _, group_role in ipairs(group_roles) do
            table.insert(roles, {
                role = group_role.role,
                domain = group_role.domain
            })
		end
	end

	res.body = util.to_json({roles = roles})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return user_roles_c
