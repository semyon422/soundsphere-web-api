local Controller = require("Controller")

local check_c = Controller:new()

check_c.path = "/auth/check"
check_c.methods = {"GET"}

check_c.context.GET = {"session"}
check_c.policies.GET = {{"permit"}}
check_c.GET = function(request)
	return 200, {
		session = request.context.session,
		request_session_id = request.session.id,
	}
end

return check_c
