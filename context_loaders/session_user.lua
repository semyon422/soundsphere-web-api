local Users = require("models.users")

local context_loader = {}

function context_loader:load_context(request)
	if request.context.user then return print("context.user") end
	local user_id = request.session.user_id
	if user_id then
		request.context.session_user = Users:find(user_id)
	end
end

return context_loader
