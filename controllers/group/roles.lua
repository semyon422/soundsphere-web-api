local group_roles = require("models.group_roles")
local util = require("lapis.util")
local preload = require("lapis.db.model").preload

local group_roles_c = {}

group_roles_c.GET = function(req, res, go)
    local sub_group_roles = group_roles:find_all({req.params.group_id}, "group_id")
	preload(sub_group_roles, "role", "domain")

	res.body = util.to_json({roles = sub_group_roles})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return group_roles_c
