local groups = require("models.groups")

local context_loader = {}

function context_loader:load_context(context)
	if context.group then return print("context.group") end
	local group_id = context.req.params.group_id
	if group_id then
		context.group = groups:find(group_id)
	end
end

return context_loader