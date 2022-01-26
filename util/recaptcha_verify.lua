local http = require("lapis.nginx.http")
local util = require("lapis.util")
local config = require("lapis.config").get()

return function(ip, token, action, score)
	if not config.recaptcha.is_enabled then
		return true
	end

	local body, status_code, headers = http.simple("https://www.google.com/recaptcha/api/siteverify", {
		secret = config.recaptcha.secret_key,
		response = token,
		remoteip = ip
	})
	if status_code ~= 200 then
		return false, "/siteverify returned " .. status_code
	end
	local captcha = util.from_json(body)

	score = score or 0.5
	if not captcha.success or captcha.score < score or captcha.action ~= action then
		return false,  ("not captcha.success or captcha.score < %s or captcha.action ~= %q"):format(
			score, action
		)
	end

	return true
end
