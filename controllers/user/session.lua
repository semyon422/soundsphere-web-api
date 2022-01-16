local Sessions = require("models.sessions")
local Controller = require("Controller")

local user_session_c = Controller:new()

user_session_c.path = "/users/:user_id[%d]/sessions/:session_id[%d]"
user_session_c.methods = {"DELETE"}

user_session_c.context.DELETE = {"request_session", "session"}
user_session_c.policies.DELETE = {{"authed", "not_request_session"}}
user_session_c.DELETE = function(self)
	local session = self.context.session
	local request_session = self.context.request_session

	session.active = false
	session:update("active")

	return {status = 204}
end

return user_session_c
