local jwt = require("luajwt")
local secret = require("secret")

local logout_c = {}

logout_c.POST = function(request)
	local session = request.context.session

	if not session or session.active == 0 then
		return 200, {
			message = "not session or session.active == 0"
		}
	end

	session.active = 0
	session:update("active")

	return 200, {}
end

return logout_c
