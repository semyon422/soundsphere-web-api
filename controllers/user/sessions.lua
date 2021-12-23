local Sessions = require("models.sessions")
local Controller = require("Controller")

local user_sessions_c = Controller:new()

user_sessions_c.path = "/users/:user_id[%d]/sessions"
user_sessions_c.methods = {"GET"}

user_sessions_c.policies.GET = {{"permit"}}
user_sessions_c.GET = function(request)
	local params = request.params
	local sessions = Sessions:find_all({params.user_id}, {
		key = "user_id",
		where = {
			active = true
		}
	})
	
	local safe_sessions = {}
	for _, session in ipairs(sessions) do
		table.insert(safe_sessions, Sessions:safe_copy(session))
	end

	return 200, {sessions = safe_sessions}
end

return user_sessions_c
