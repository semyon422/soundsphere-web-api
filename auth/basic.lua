local base64 = require("base64")

return function(header)
	if not header then return end
	local schema, token = header:match("^(.+) (.+)$")
	if schema ~= "Basic" then return end
	if not token then return end
	local email_password = base64.decode(token)
	if not email_password then return end
    local email, password = email_password:match("^(.-):(.*)$")
    if not email then
        return
    end
	return {
        email = email,
        password = password
    }
end
