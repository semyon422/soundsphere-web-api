local Sessions = require("models.sessions")

local sessions_c = {}

sessions_c.GET = function(request)
	local params = request.params
	local sessions = Sessions:find_all({params.user_id}, "user_id")

	return 200, {sessions = sessions}
end

return sessions_c
