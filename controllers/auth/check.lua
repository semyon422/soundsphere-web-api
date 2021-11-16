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
	return 200, {
		session = request.context.session,
		request_session_id = request.session.id,
	}
end

return check_c
