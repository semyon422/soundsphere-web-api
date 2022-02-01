local Users = require("models.users")
local rand = require("openssl.rand")
local Bypass_actions = require("enums.bypass_actions")
local Bypass_keys = require("models.bypass_keys")
local Filehash = require("util.filehash")
local util = require("util")
local Controller = require("Controller")

local reset_c = Controller:new()

reset_c.path = "/auth/reset"
reset_c.methods = {"POST"}
reset_c.captcha = true

reset_c.policies.POST = {{"permit"}}
reset_c.validations.POST = {
	{"email", exists = true, type = "string", param_type = "body"},
	{"recaptcha_token", exists = true, type = "string", param_type = "body", captcha = "reset", optional = true},
	{"bypass_key", exists = true, type = "string", param_type = "body", optional = true},
}
reset_c.POST = function(self)
	local params = self.params

	local bypass_key
	local bypass = false
	if params.bypass_key then
		bypass_key = Bypass_keys:find({
			key = Filehash:for_db(params.bypass_key),
		})
		if bypass_key then
			bypass_key:to_name()
			if bypass_key.action == "password" and bypass_key.expires_at > os.time() then
				bypass = true
			end
		end
	end

	if not bypass then
		local success, message = util.recaptcha_verify(
			self.context.ip,
			params.recaptcha_token,
			"reset",
			0.5
		)
		if not success then
			return {status = 401, json = {message = message}}
		end
	end

	local user = Users:find({email = params.email:lower()})

	if not user then
		return {status = 401, json = {message = "User not found"}}
	end

	if bypass_key then
		if bypass_key.target_user_id ~= user.id then
			return {status = 401, json = {message = "Used bypass key is not allowed for this user"}}
		end
		bypass_key:delete()
	end

	local reset_bypass_key = Bypass_keys:find({
		action = Bypass_actions:for_db("password"),
		user_id = user.id,
		target_user_id = user.id,
	})
	if reset_bypass_key then
		reset_bypass_key.expires_at = os.time() + 3600
		reset_bypass_key:update("expires_at")
	else
		reset_bypass_key = Bypass_keys:create({
			key = rand.bytes(16),
			action = Bypass_actions:for_db("password"),
			user_id = user.id,
			target_user_id = user.id,
			created_at = os.time(),
			expires_at = os.time() + 3600,
		})
	end
	reset_bypass_key:to_name()
	-- send reset_bypass_key.key on email

	util.redirect_to(self, self:url_for(reset_bypass_key))
	return {status = 201, json = {id = reset_bypass_key.id}}
end

return reset_c
