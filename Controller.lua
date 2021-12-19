local pep = require("abac.PolicyEnforcementPoint")
local autoload = require("lapis.util").autoload
local context_loaders = autoload("context_loaders")

local Controller = {}

Controller.new = function(self)
	return setmetatable({}, {__index = self})
end

Controller.check_access = function(self, request, method)
	method = method or request.req.method
	if not self[method] then
		return
	end
	return pep:check(request, self.policies[method])
end

Controller.load_context = function(self, request, method)
	method = method or request.req.method
	if not self[method] or not self.context then
		return
	end
	for _, name in ipairs(self.context) do
		context_loaders[name](request)
	end
	if not self.context[method] then
		return
	end
	for _, name in ipairs(self.context[method]) do
		context_loaders[name](request)
	end
end

return Controller
