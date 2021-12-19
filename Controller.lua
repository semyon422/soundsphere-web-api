local pep = require("abac.PolicyEnforcementPoint")

local Controller = {}

Controller.new = function(self)
	return setmetatable({}, {__index = self})
end

Controller.check_access = function(self, request, method)
	method = method or request.method
	if not self[method] then
		return
	end
	return pep:check(request, self.policies[method])
end

return Controller
