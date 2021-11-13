local Sessions = require("models.sessions")

local context_loader = {}

function context_loader:load_context(request)
	if request.context.session then return print("context.session") end
	local session_id = request.session.id
	if session_id then
		request.context.session = Sessions:find(request.session.id)
	end
end

return context_loader
