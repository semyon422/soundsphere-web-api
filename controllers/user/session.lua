local Sessions = require("models.sessions")
local Controller = require("Controller")

local user_session_c = Controller:new()

user_session_c.path = "/users/:user_id[%d]/sessions/:session_id[%d]"
user_session_c.methods = {"DELETE"}

user_session_c.context.DELETE = {"session"}
user_session_c.policies.DELETE = {{"authenticated", "context_loaded"}}
user_session_c.DELETE = function(request)
	local session = request.context.session
	session.active = false
	session:update("active")

	return 200, {}
end

return user_session_c
