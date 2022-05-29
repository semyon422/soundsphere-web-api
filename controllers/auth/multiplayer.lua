local Controller = require("Controller")
local http = require("lapis.nginx.http")
local config = require("lapis.config").get()

local multiplayer_c = Controller:new()

multiplayer_c.path = "/auth/multiplayer"
multiplayer_c.methods = {"POST"}

multiplayer_c.context.POST = {"request_session", "session_user"}
multiplayer_c.policies.POST = {{"authed"}}
multiplayer_c.validations.POST = {
	{"key", type = "string", param_type = "body"},
}
multiplayer_c.POST = function(self)
	local session_user = self.context.session_user

	local port = config.multiplayer_http_port
	local body, code, headers = http.simple({
		url = "http://127.0.0.1:" .. port .. "/login",
		method = "POST",
		body = {
			token = config.multiplayer_http_token,
			key = self.params.key,
			user_id = session_user.id,
			user_name = session_user.name,
		},
	})

	return {status = code}
end

return multiplayer_c
