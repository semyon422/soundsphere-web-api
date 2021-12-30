local Controller = require("Controller")

local auth_c = Controller:new()

auth_c.path = "/auth"
auth_c.methods = {"GET"}

auth_c.policies.GET = {{"permit"}}
auth_c.GET = function(request)
	return {}
end

return auth_c
