local Groups = require("models.groups")

local context_loader = {}

function context_loader:load_context(request)
	if request.context.group then return print("context.group") end
	local group_id = request.params.group_id
	if group_id then
		request.context.group = Groups:find(group_id)
	end
end

return context_loader
