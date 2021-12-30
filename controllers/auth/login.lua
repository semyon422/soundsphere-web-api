local preload = require("lapis.db.model").preload
local Users = require("models.users")
local Sessions = require("models.sessions")
local bcrypt = require("bcrypt")
local jwt = require("luajwt")
local secret = require("secret")
local Controller = require("Controller")
local Ip = require("util.ip")

local login_c = Controller:new()

login_c.path = "/auth/login"
login_c.methods = {"POST"}

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
	local token, err = jwt.encode(payload, secret.token_key, "HS256")

	return token, payload
end

login_c.policies.POST = {{"permit"}}
login_c.validations.POST = {
	{"email", exists = true, type = "string", param_type = "body"},
	{"password", exists = true, type = "string", param_type = "body"},
}
login_c.POST = function(self)
	local params = self.params

	local user, err = login(params.email, params.password)

	if not user then
		return {json = {message = err}}
	end

	local token, payload = login_c.new_token(user, self.context.ip)

	login_c.copy_session(payload, self.session)

	return {json = {
		token = token,
		session = payload,
	}}
end

return login_c
