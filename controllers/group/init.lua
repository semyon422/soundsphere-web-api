local Groups = require("models.groups")

local group_c = {}

group_c.GET = function(request)
	local params = request.params
	local group = Groups:find(params.group_id)

	return 200, {group = group}
end

return group_c
