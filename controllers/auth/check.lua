local Sessions = require("models.sessions")
local Controller = require("Controller")

local check_c = Controller:new()

check_c.path = "/auth/check"
check_c.methods = {"GET", "POST"}

check_c.context.GET = {"request_session"}
check_c.policies.GET = {{"permit"}}
check_c.validations.GET = {
	{"show_ip", type = "boolean", optional = true}
}
check_c.GET = function(self)
	local session = self.context.request_session:to_name()
	if not self.params.show_ip then
		session.ip = nil
	end
	return {json = {
		session = session,
		request_session_id = self.session.id,
	}}
end

check_c.context.POST = {"request_session"}
check_c.policies.POST = {{"authenticated"}}
check_c.POST = check_c.GET

return check_c
