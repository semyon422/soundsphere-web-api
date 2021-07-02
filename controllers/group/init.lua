local groups = require("models.groups")
local util = require("lapis.util")

local group_c = {}

group_c.GET = function(params)
	local db_group_entry = groups:find(params.group_id)

	return 200, {group = db_group_entry}
end

return group_c
