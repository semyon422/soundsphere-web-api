local jwt = require("luajwt")
local config = require("lapis.config").get()

return function(header)
	if not header then return end
	local schema, token = header:match("^(.+) (.+)$")
	if schema ~= "Bearer" then return end
	if not token then return end
	local payload, err = jwt.decode(token, config.secret)
	if not payload then return end
	return payload
end
