local Group_roles = require("models.group_roles")
local Roles = require("models.roles")
local preload = require("lapis.db.model").preload

local group_roles_c = {}

group_roles_c.GET = function(params)
    local group_roles = Group_roles:find_all({params.group_id}, "group_id")
	preload(group_roles, "domain")

	return 200, {roles = group_roles}
end

return group_roles_c
