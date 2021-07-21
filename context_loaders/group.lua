local Groups = require("models.groups")

local context_loader = {}

function context_loader:load_context(context)
	if context.group then return print("context.group") end
	local group_id = context.params.group_id
	if group_id then
		context.group = Groups:find(group_id)
	end
end

return context_loader
