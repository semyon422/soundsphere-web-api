local encoding = require("lapis.util.encoding")
local login_c = require("controllers.auth.login")
local Controller = require("Controller")

local update_c = Controller:new()

update_c.path = "/auth/update"
update_c.methods = {"POST"}

update_c.context.POST = {"request_session"}
update_c.policies.POST = {{"authed"}}
update_c.POST = function(self)
	local session = self.context.request_session

	if session.updated_at - self.session.updated_at ~= 0 then
		session.active = false
		session:update("active")
		return {status = 403, json = {message = "session.updated_at ~= request.session.updated_at"}}
	end

	session.updated_at = os.time()
	session:update("updated_at")

	local payload = login_c.copy_session(session:to_name())
	local token = encoding.encode_with_secret(payload)
	login_c.copy_session(payload, self.session)

	return {json = {
		token = token,
		session = payload,
	}}
end

return update_c
