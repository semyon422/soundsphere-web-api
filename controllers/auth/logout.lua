local Sessions = require("models.sessions")
local jwt = require("luajwt")
local secret = require("secret")

local logout_c = {}

logout_c.POST = function(request)
	local token = request.params.token
	local decoded, err = jwt.decode(token, secret.token_key, true)

	if not decoded then
		return 200, {}
	end

	local session = Sessions:find(decoded.session_id)

	session.active = false
	session:update("active")

	return 200, {}
end

return logout_c
