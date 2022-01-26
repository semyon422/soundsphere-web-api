local Users = require("models.users")
local Sessions = require("models.sessions")
local User_locations = require("models.user_locations")
local bcrypt = require("bcrypt")
local encoding = require("lapis.util.encoding")
local util = require("util")
local Controller = require("Controller")
local Ip = require("util.ip")

local login_c = Controller:new()

login_c.path = "/auth/login"
login_c.methods = {"POST"}
login_c.captcha = true

local failed = "Login failed. Invalid email or password"
local function login(email, password)
	if not email or not password then return false, failed end
	local user = Users:find({email = email:lower()})
	if not user then return false, failed end
	local valid = bcrypt.verify(password, user.password)
	if valid then return user end
	return false, failed
end

login_c.copy_session = function(src, dst)
	dst = dst or {}
	dst.id = tonumber(src.id)
	dst.user_id = tonumber(src.user_id)
	dst.created_at = tonumber(src.created_at)
	dst.updated_at = tonumber(src.updated_at)
	return dst
end

login_c.add_user_location = function(user, ip, is_register)
	local new_user_location = {
		user_id = user.id,
		ip = Ip:for_db(ip),
	}
	local user_location = User_locations:find(new_user_location)
	if not user_location then
		local time = os.time()
		new_user_location.created_at = time
		new_user_location.updated_at = time
		new_user_location.is_register = is_register
		new_user_location.sessions_count = 1
		user_location = User_locations:create(new_user_location)
		return
	end
	user_location.updated_at = os.time()
	user_location.sessions_count = user_location.sessions_count + 1
	user_location:update("updated_at", "sessions_count")
end

login_c.new_token = function(user, ip)
	local time = os.time()
	local session = Sessions:create({
		user_id = user.id,
		active = true,
		ip = Ip:for_db(ip),
		created_at = time,
		updated_at = time,
	})

	local payload = login_c.copy_session(session:to_name())
	local token = encoding.encode_with_secret(payload)

	return token, payload
end

login_c.policies.POST = {{"permit"}}
login_c.validations.POST = {
	{"email", exists = true, type = "string", param_type = "body"},
	{"password", exists = true, type = "string", param_type = "body"},
	{"recaptcha_token", exists = true, type = "string", param_type = "body", captcha = "login", optional = true},
}
login_c.POST = function(self)
	local params = self.params

	local success, message = util.recaptcha_verify(
		self.context.ip,
		params.recaptcha_token,
		"login",
		0.5
	)
	if not success then
		return {status = 401, json = {message = message}}
	end

	local user, err = login(params.email, params.password)

	if not user then
		return {status = 401, json = {message = err}}
	end

	local token, payload = login_c.new_token(user, self.context.ip)
	login_c.add_user_location(user, self.context.ip, false)
	login_c.copy_session(payload, self.session)

	return {json = {
		token = token,
		session = payload,
	}}
end

return login_c
