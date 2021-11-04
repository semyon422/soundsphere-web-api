local Users = require("models.users")

local context_loader = {}

function context_loader:load_context(request)
	if request.context.user then return print("context.user") end
	local token = request.context.token
	if token then
		request.context.token_user = Users:find(token.user_id)
	end
end

return context_loader
