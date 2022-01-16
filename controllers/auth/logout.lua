local Controller = require("Controller")

local logout_c = Controller:new()

logout_c.path = "/auth/logout"
logout_c.methods = {"POST"}

logout_c.context.POST = {"request_session"}
logout_c.policies.POST = {{"authed"}}
logout_c.POST = function(self)
	local session = self.context.request_session

	session.active = false
	session:update("active")

	for key, value in pairs(session) do
		self.session[key] = nil
	end

	return {}
end

return logout_c
