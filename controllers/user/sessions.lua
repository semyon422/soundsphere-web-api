local Sessions = require("models.sessions")

local user_sessions_c = {}

user_sessions_c.path = "/users/:user_id/sessions"
user_sessions_c.methods = {"GET"}
user_sessions_c.context = {}
user_sessions_c.policies = {
	GET = require("policies.public"),
}

user_sessions_c.GET = function(request)
	local params = request.params
	local sessions = Sessions:find_all({params.user_id}, "user_id")

	return 200, {sessions = sessions}
end

return user_sessions_c
