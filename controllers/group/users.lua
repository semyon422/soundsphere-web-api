local users = require("models.users")
local group_users = require("models.group_users")
local util = require("lapis.util")
local preload = require("lapis.db.model").preload

local group_users_c = {}

group_users_c.GET = function(req, res, go)
    local sub_group_users = group_users:find_all({req.params.group_id}, "group_id")

	res.body = util.to_json({users = sub_group_users})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return group_users_c
