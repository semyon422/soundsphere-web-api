local Controller = require("Controller")
local Bypass_keys = require("models.bypass_keys")
local Filehash = require("util.filehash")
local Users = require("models.users")
local bcrypt = require("bcrypt")

local password_c = Controller:new()

password_c.path = "/auth/password"
password_c.methods = {"POST", "PUT"}

password_c.context.POST = {"request_session", "session_user"}
password_c.policies.POST = {{"authed"}}
password_c.validations.POST = {
	{"old_password", type = "string", param_type = "body"},
	{"password", type = "string", param_type = "body"},
	{"confirm_password", type = "string", param_type = "body"},
}
password_c.POST = function(self)
	local params = self.params
	local session_user = self.context.session_user

	if params.password ~= params.confirm_password then
		return {status = 400, json = {message = "params.password ~= params.confirm_password"}}
	end

	if not bcrypt.verify(params.old_password, session_user.password) then
		return {status = 401, json = {message = "Invalid old password"}}
	end

	session_user.password = bcrypt.digest(params.password, 10)
	session_user:update("password")

	return {}
end

password_c.policies.PUT = {{"permit"}}
password_c.validations.PUT = {
	{"password", type = "string", param_type = "body"},
	{"confirm_password", type = "string", param_type = "body"},
	{"bypass_key", type = "string", param_type = "body"},
}
password_c.PUT = function(self)
	local params = self.params

	if params.password ~= params.confirm_password then
		return {status = 400, json = {message = "params.password ~= params.confirm_password"}}
	end

	local bypass_key = Bypass_keys:find({
		key = Filehash:for_db(params.bypass_key),
	})
	if bypass_key then
		bypass_key:to_name()
	end
	if not bypass_key or bypass_key.action ~= "password" or bypass_key.expires_at <= os.time() then
		return {status = 401, json = {message = "Wrong bypass key"}}
	end

	local user = Users:find(bypass_key.target_user_id)
	if not user then
		return {status = 401, json = {message = "User not found"}}
	end

	user.password = bcrypt.digest(params.password, 10)
	user:update("password")

	bypass_key:delete()

	return {}
end

return password_c
