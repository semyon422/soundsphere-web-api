local Sessions = require("models.sessions")

local user_session_c = {}

user_session_c.path = "/users/:user_id/sessions/:session_id"
user_session_c.methods = {"DELETE"}
user_session_c.context = {}
user_session_c.policies = {
	DELETE = require("policies.public"),
}

user_session_c.DELETE = function(request)
	local params = request.params
	local session = Sessions:find(params.session_id)
	if session then
		session.active = false
		session:update("active")
	end

	return 200, {}
end

return user_session_c
