local Sessions = require("models.sessions")
local Controller = require("Controller")

local user_session_c = Controller:new()

user_session_c.path = "/users/:user_id[%d]/sessions/:session_id[%d]"
user_session_c.methods = {"DELETE"}

user_session_c.policies.DELETE = {{"permit"}}
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
