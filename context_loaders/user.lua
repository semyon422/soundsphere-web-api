local Users = require("models.users")

local context_loader = {}

function context_loader:load_context(context)
	if context.user then return print("context.user") end
	local user_id = context.req.params.user_id
	if user_id then
		context.user = Users:find(user_id)
	end
end

return context_loader
