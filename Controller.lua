local pep = require("abac.PolicyEnforcementPoint")
local autoload = require("lapis.util").autoload
local context_loaders = autoload("context_loaders")

local Controller = {}

Controller.new = function(self)
	return setmetatable({
		methods = {},
		context = {},
		policies = {},
		validation = {},
	}, {__index = self})
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
	if not self[method] or not self.context[method] then
		return
	end
	for _, name in ipairs(self.context[method]) do
		context_loaders[name](request)
	end
end

Controller.get_params = function(self)
	local params = {}
	for key in self.path:gmatch(":([^/^%[]+)") do
		table.insert(params, key)
	end
	return params
end

Controller.get_missing_params = function(self, params)
	local path_params = {}
	for key in self.path:gmatch(":([^/^%[]+)") do
		path_params[key] = true
	end
	local missing_params = {}
	for key in pairs(path_params) do
		if not params[key] then
			table.insert(missing_params, key)
		end
	end
	return missing_params
end

return Controller
