local jwt = require("luajwt")

local key = "example_key"

return function(req)
	local authorization = req.headers.Authorization
	if not authorization then return end
	local schema, token = authorization:match("^(.+) (.+)$")
	if schema ~= "Bearer" then return end
	if not token then return end
	local payload, err = jwt.decode(token, key)
	if not payload then return end
	return payload
end
