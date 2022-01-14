local util = require("lapis.util")
local http = require("lapis.nginx.http")
local secret = require("secret")

local Recaptcha = {}

Recaptcha.verify = function(self, response, ip)
	local body, status_code, headers = http.simple("https://www.google.com/recaptcha/api/siteverify", {
		secret = secret.recaptcha_secret,
		response = response,
		remoteip = ip
	})

	return util.from_json(body)
end

return Recaptcha
