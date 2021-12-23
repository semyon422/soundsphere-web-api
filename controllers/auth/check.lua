local Sessions = require("models.sessions")
local Controller = require("Controller")

local check_c = Controller:new()

check_c.path = "/auth/check"
check_c.methods = {"GET", "POST"}

check_c.context.GET = {"session"}
check_c.policies.GET = {{"permit"}}
check_c.GET = function(request)
	return 200, {
		session = Sessions:safe_copy(request.context.session),
		request_session_id = request.session.id,
	}
end

check_c.context.POST = {"session"}
check_c.policies.POST = {{"authenticated"}}
check_c.POST = function(request)
	return 200, {
		session = Sessions:safe_copy(request.context.session),
		request_session_id = request.session.id,
	}
end

return check_c
