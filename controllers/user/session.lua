local Sessions = require("models.sessions")

local session_c = {}

session_c.DELETE = function(request)
	local params = request.params
	local session = Sessions:find(params.session_id)
	if session then
		session.active = false
		session:update("active")
	end

	return 200, {}
end

return session_c
