local group_roles = require("models.group_roles")
local util = require("lapis.util")
local preload = require("lapis.db.model").preload

local group_roles_c = {}

group_roles_c.GET = function(params)
    local sub_group_roles = group_roles:find_all({params.group_id}, "group_id")
	preload(sub_group_roles, "role", "domain")

	return 200, {roles = sub_group_roles}
end

return group_roles_c
