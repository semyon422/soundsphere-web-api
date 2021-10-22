local Sessions = require("models.sessions")

local session_c = {}

session_c.DELETE = function(params)
	local session = Sessions:find(params.session_id)
	if session then
		session.active = false
		session:update("active")
	end

	return 200, {}
end

return session_c
