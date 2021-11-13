local Group_users = require("models.group_users")
local preload = require("lapis.db.model").preload

local user_groups_c = {}

user_groups_c.path = "/users/:user_id/groups"
user_groups_c.methods = {"GET"}
user_groups_c.context = {}
user_groups_c.policies = {
	GET = require("policies.public"),
}

user_groups_c.GET = function(request)
	local params = request.params
    local group_users = Group_users:find_all({params.user_id}, "user_id")
	preload(group_users, "group")

    local groups = {}
	for _, group_user in ipairs(group_users) do
        table.insert(groups, group_user.group)
	end

	local count = Group_users:count()

	return 200, {
		total = count,
		filtered = count,
		groups = groups
	}
end

return user_groups_c
