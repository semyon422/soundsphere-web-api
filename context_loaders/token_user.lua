local users = require("models.users")

local context_loader = {}

function context_loader:load_context(context)
	if context.user then return print("context.user") end
	local token = context.req.token
	if token then
		context.token_user = users:find(token.user_id)
	end
end

return context_loader