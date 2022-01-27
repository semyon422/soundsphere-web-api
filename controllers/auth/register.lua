local Users = require("models.users")
local User_roles = require("models.user_roles")
local User_locations = require("models.user_locations")
local Bypass_keys = require("models.bypass_keys")
local Filehash = require("util.filehash")
local bcrypt = require("bcrypt")
local Controller = require("Controller")
local Roles = require("enums.roles")
local Ip = require("util.ip")
local util = require("util")
local login_c = require("controllers.auth.login")

local config = require("lapis.config").get()

local register_c = Controller:new()

register_c.path = "/auth/register"
register_c.methods = {"POST"}
register_c.captcha = true

register_c.policies.POST = {{"permit"}}
register_c.validations.POST = {
	{"user", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"email", exists = true, type = "string"},
		{"password", exists = true, type = "string"},
	}},
	{"game_name", exists = true, type = "string", param_type = "body", optional = true},
	{"recaptcha_token", exists = true, type = "string", param_type = "body", captcha = "register", optional = true},
	{"bypass_key", exists = true, type = "string", param_type = "body", optional = true},
}
register_c.POST = function(self)
	local params = self.params

	if params.game_name ~= "soundsphere" then
		return {status = 400, json = {message = "Wrong game name"}}
	end

	local bypass_key
	local bypass = false
	if params.bypass_key then
		bypass_key = Bypass_keys:find({
			key = Filehash:for_db(params.bypass_key),
		})
		if bypass_key then
			bypass_key:to_name()
			if bypass_key.action == "register" and bypass_key.expires_at > os.time() then
				bypass = true
			end
		end
	end

	if not bypass then
		if not config.is_register_enabled then
			return {status = 401, json = {message = "Registration is disabled"}}
		end

		local success, message = util.recaptcha_verify(
			self.context.ip,
			params.recaptcha_token,
			"register",
			0.5
		)
		if not success then
			return {status = 401, json = {message = message}}
		end

		local user_location = User_locations:select(
			"where ip = ? and is_register = ? order by created_at desc limit 1",
			Ip:for_db(self.context.ip),
			true
		)[1]
		if user_location and user_location.created_at + config.ip_register_delay > os.time() then
			return {status = 400, json = {message = "Registration for this IP is temporarily not allowed"}}
		end
	end

	local user = Users:find({email = params.user.email:lower()})
	if user then
		return {status = 400, json = {message = "This email is already registered"}}
	end
	user = Users:find({name = params.user.name})
	if user then
		return {status = 400, json = {message = "This name is already taken"}}
	end

	if bypass_key then
		bypass_key:delete()
	end

	local time = os.time()
	user = Users:create({
		name = params.user.name,
		email = params.user.email:lower(),
		password = bcrypt.digest(params.user.password, 10),
		latest_activity = time,
		created_at = time,
		description = "",
		scores_count = 0,
		notecharts_count = 0,
		play_time = 0,
	})
	User_roles:create({
		user_id = user.id,
		role = Roles:for_db("user"),
	})

	local token, payload = login_c.new_token(user, self.context.ip)
	login_c.add_user_location(user, self.context.ip, true)
	login_c.copy_session(payload, self.session)

	return {status = 201, redirect_to = self:url_for(user)}
end

return register_c
