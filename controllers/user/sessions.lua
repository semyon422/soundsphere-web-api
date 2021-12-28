local Sessions = require("models.sessions")
local Controller = require("Controller")

local user_sessions_c = Controller:new()

user_sessions_c.path = "/users/:user_id[%d]/sessions"
user_sessions_c.methods = {"GET"}

user_sessions_c.context.GET = {"request_session"}
user_sessions_c.policies.GET = {{"authenticated"}}
user_sessions_c.GET = function(request)
	local params = request.params
	local sessions = Sessions:find_all({params.user_id}, {
		key = "user_id",
		where = {
			active = true
		}
	})

	local request_session = request.context.request_session
	local request_session_id = request_session and request_session.id
	
	local safe_sessions = {}
	for _, session in ipairs(sessions) do
		local safe_session = Sessions:safe_copy(session)
		if request_session_id and request_session_id == safe_session.id then
			safe_session.is_current = true
		end
		table.insert(safe_sessions, safe_session)
	end

	return 200, {sessions = safe_sessions}
end

return user_sessions_c
