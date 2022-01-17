local Users = require("models.users")
local User_roles = require("models.user_roles")
local bcrypt = require("bcrypt")
local Controller = require("Controller")
local Roles = require("enums.roles")
local util = require("util")
local login_c = require("controllers.auth.login")

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
	{"recaptcha_token", exists = true, type = "string", param_type = "body", captcha = "register"},
}
register_c.POST = function(self)
	local params = self.params

	local captcha = util.recaptcha_verify(params.recaptcha_token, self.context.ip)
	if not captcha.success or captcha.score < 0.5 or captcha.action ~= "register" then
		return {status = 401, json = {
			message = [[not captcha.success or captcha.score < 0.5 or captcha.action ~= "register"]]
		}}
	end

	local user = Users:find({email = params.user.email:lower()})
	if user then
		return {json = {message = "This email is already registered"}}
	end
	user = Users:find({name = params.user.name})
	if user then
		return {status = 400, json = {message = "This name is already taken"}}
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
	login_c.copy_session(payload, self.session)

	return {status = 201, redirect_to = self:url_for(user)}
end

return register_c
