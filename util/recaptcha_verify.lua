local http = require("lapis.nginx.http")
local util = require("lapis.util")
local config = require("lapis.config").get()

return function(response, ip)
	local body, status_code, headers = http.simple("https://www.google.com/recaptcha/api/siteverify", {
		secret = config.recaptcha.secret_key,
		response = response,
		remoteip = ip
	})
	if status_code ~= 200 then
		return {
			body = body,
			status_code = status_code,
			headers = headers,
		}
	end
	return util.from_json(body)
end
