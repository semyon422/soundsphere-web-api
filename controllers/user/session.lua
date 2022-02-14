local Sessions = require("models.sessions")
local Controller = require("Controller")

local user_session_c = Controller:new()

user_session_c.path = "/users/:user_id[%d]/sessions/:session_id[%d]"
user_session_c.methods = {"DELETE"}

user_session_c.context.DELETE = {"user", "session", "request_session", "session_user", "user_roles"}
user_session_c.policies.DELETE = {
	{"authed", "user_profile", "not_request_session"},
	{"authed", "not_request_session", {role = "moderator"}},
	{"authed", "not_request_session", {role = "admin"}},
	{"authed", "not_request_session", {role = "creator"}},
}
user_session_c.DELETE = function(self)
	local session = self.context.session
	local request_session = self.context.request_session

	session.active = false
	session:update("active")

	return {status = 204}
end

return user_session_c
