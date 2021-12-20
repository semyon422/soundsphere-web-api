local Sessions = require("models.sessions")
local Controller = require("Controller")

local user_sessions_c = Controller:new()

user_sessions_c.path = "/users/:user_id[%d]/sessions"
user_sessions_c.methods = {"GET"}

user_sessions_c.policies.GET = {{"permit"}}
user_sessions_c.GET = function(request)
	local params = request.params
	local sessions = Sessions:find_all({params.user_id}, "user_id")

	return 200, {sessions = sessions}
end

return user_sessions_c
