local group_users = require("models.group_users")
local util = require("lapis.util")
local preload = require("lapis.db.model").preload

local user_groups_c = {}

user_groups_c.GET = function(req, res, go)
    local sub_group_users = group_users:find_all({req.params.user_id}, "user_id")
	preload(sub_group_users, "group")

    local groups = {}
	for _, group_user in ipairs(sub_group_users) do
        table.insert(groups, group_user.group)
	end

	res.body = util.to_json({groups = groups})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return user_groups_c
