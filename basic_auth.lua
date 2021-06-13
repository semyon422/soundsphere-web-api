local base64 = require("base64")

return function(req)
	local authorization = req.headers.Authorization
	if not authorization then return end
	local schema, token = authorization:match("^(.+) (.+)$")
	if schema ~= "Basic" then return end
	if not token then return end
	local email_password = base64.decode(token)
	if not email_password then return end
    local email, password = email_password:match("^(.-):(.*)$")
    if not email then
        return
    end
	req.basic = {
        email = email,
        password = password
    }
end
