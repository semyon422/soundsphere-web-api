local Controller = require("Controller")

local logout_c = Controller:new()

logout_c.path = "/auth/logout"
logout_c.methods = {"POST"}

logout_c.context.POST = {"request_session"}
logout_c.policies.POST = {{"authenticated"}}
logout_c.POST = function(request)
	local session = request.context.request_session

	session.active = false
	session:update("active")

	for key, value in pairs(session) do
		request.session[key] = nil
	end

	return 200, {}
end

return logout_c
