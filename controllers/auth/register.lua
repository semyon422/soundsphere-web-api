local Users = require("models.users")
local bcrypt = require("bcrypt")
local Controller = require("Controller")
local login_c = require("controllers.auth.login")

local register_c = Controller:new()

register_c.path = "/auth/register"
register_c.methods = {"POST"}

register_c.policies.POST = {{"permit"}}
register_c.validations.POST = {
	{"user", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"email", exists = true, type = "string"},
		{"password", exists = true, type = "string"},
	}}
}
register_c.POST = function(self)
	local params = self.params

	local user = Users:find({email = params.user.email:lower()})
	if user then
		return {json = {message = "This email is already registered"}}
	end
	user = Users:find({name = params.user.name})
	if user then
		return {json = {message = "This name is already taken"}}
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

	local token, payload = login_c.new_token(user, self.context.ip)
	login_c.copy_session(payload, self.session)

	return {status = 201, redirect_to = self:url_for(user)}
end

return register_c
