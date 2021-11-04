local Roles = require("models.roles")

local context_loader = {}

function context_loader:load_context(request)
	if request.context.role then return print("context.role") end
	local role_id = request.params.role_id
	if role_id then
		request.context.role = Roles:find(role_id)
	end
end

return context_loader
