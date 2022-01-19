local encoding = require("lapis.util.encoding")

return function(header)
	if not header then return end
	local schema, token = header:match("^(.+) (.+)$")
	if schema ~= "Bearer" then return end
	if not token then return end
	local payload, err = encoding.decode_with_secret(token)
	if not payload then return end
	return payload
end
