local jwt = require("luajwt")
local secret = require("secret")

local check_c = {}

check_c.path = "/auth/check"
check_c.methods = {"GET"}
check_c.context = {"session"}
check_c.policies = {
	GET = require("policies.public"),
}

check_c.GET = function(request)
	local session = request.context.session

	if not session or session.active == 0 then
		return 200, {
			message = "not session or session.active == 0"
		}
	end

	return 200, {session = session}
end

return check_c
