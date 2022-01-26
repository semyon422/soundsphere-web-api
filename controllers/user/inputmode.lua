local User_inputmodes = require("models.user_inputmodes")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")

local user_inputmode_c = Controller:new()

user_inputmode_c.path = "/users/:user_id[%d]/inputmodes/:inputmode"
user_inputmode_c.methods = {"GET", "PUT", "DELETE"}
user_inputmode_c.validations.path = {
	{"inputmode", type = "string", one_of = Inputmodes.list, param_type = "path"},
}

user_inputmode_c.context.GET = {"user_inputmode", "request_session"}
user_inputmode_c.policies.GET = {{"authed"}}
user_inputmode_c.GET = function(self)
    local user_inputmode = self.context.user_inputmode
	return {json = {user_inputmode = user_inputmode:to_name()}}
end

user_inputmode_c.context.PUT = {
	{"user_inputmode", missing = true},
	"request_session",
	"user",
	"session_user",
}
user_inputmode_c.policies.PUT = {{"authed", "user_profile"}}
user_inputmode_c.PUT = function(self)
	local params = self.params

    local user_inputmode = User_inputmodes:create({
		user_id = params.user_id,
		inputmode = Inputmodes:for_db(params.inputmode),
	})

	return {json = {user_inputmode = user_inputmode:to_name()}}
end

user_inputmode_c.context.DELETE = {"user_inputmode", "request_session", "session_user"}
user_inputmode_c.policies.DELETE = {{"authed", "user_profile"}}
user_inputmode_c.DELETE = function(self)
    local user_inputmode = self.context.user_inputmode
    user_inputmode:delete()

	return {status = 204}
end

return user_inputmode_c
