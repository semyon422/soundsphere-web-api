local Controller = require("Controller")
local login_c = require("controllers.auth.login")

local logout_c = Controller:new()

logout_c.path = "/auth/logout"
logout_c.methods = {"POST"}

logout_c.context.POST = {{"request_session", optional = true}}
logout_c.policies.POST = {{"permit"}}
logout_c.POST = function(self)
	local session = self.context.request_session

	if session then
		session.active = false
		session:update("active")
	end
	login_c.copy_session({}, self.session)

	return {}
end

return logout_c
