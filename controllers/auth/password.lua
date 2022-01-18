local Controller = require("Controller")
local bcrypt = require("bcrypt")

local password_c = Controller:new()

password_c.path = "/auth/password"
password_c.methods = {"POST"}

password_c.context.POST = {"request_session", "session_user"}
password_c.policies.POST = {{"authed"}}
password_c.validations.POST = {
	{"password", exists = true, type = "string", param_type = "body"},
	{"confirm_password", exists = true, type = "string", param_type = "body"},
}
password_c.POST = function(self)
	local params = self.params
	local session_user = self.context.session_user

	if params.password ~= params.confirm_password then
		return {status = 400, json = {message = "params.password ~= params.confirm_password"}}
	end

	session_user.password = bcrypt.digest(params.password, 10)
	session_user:update("password")

	return {}
end

return password_c
