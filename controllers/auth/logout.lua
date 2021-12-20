local Controller = require("Controller")

local logout_c = Controller:new()

logout_c.path = "/auth/logout"
logout_c.methods = {"POST"}

logout_c.context.POST = {"session"}
logout_c.policies.POST = {{"permit"}}
logout_c.POST = function(request)
	local session = request.context.session

	if not session or not session.active then
		return 200, {
			message = "not session or not session.active"
		}
	end

	session.active = false
	session:update("active")

	for key, value in pairs(session) do
		request.session[key] = nil
	end

	return 200, {}
end

return logout_c
