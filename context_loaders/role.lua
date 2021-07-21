local Roles = require("models.roles")

local context_loader = {}

function context_loader:load_context(context)
	if context.role then return print("context.role") end
	local role_id = context.params.role_id
	if role_id then
		context.role = Roles:find(role_id)
	end
end

return context_loader
