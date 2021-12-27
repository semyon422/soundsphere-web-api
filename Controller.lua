local pep = require("abac.PolicyEnforcementPoint")
local autoload = require("lapis.util").autoload
local context_loaders = autoload("context_loaders")

local Controller = {}

Controller.new = function(self)
	return setmetatable({
		methods = {},
		context = {},
		policies = {},
		validations = {},
		params = {},
		permited_methods = {},
	}, {__index = self})
end

Controller.check_access = function(self, request, method)
	method = method or request.req.method
	if not self[method] then
		return
	end
	local methods = self.permited_methods
	methods[method] = methods[method] or pep:check(request, self.policies[method])
	return methods[method] 
end

Controller.load_context = function(self, request, method)
	method = method or request.req.method
	if not self[method] or not self.context[method] then
		return true
	end
	local loaded = true
	for _, name in ipairs(self.context[method]) do
		local result = context_loaders[name](request)
		loaded = loaded and result
	end
	request.context.loaded[method] = not not loaded
	return loaded
end

local get_default_value = function(validation)
	if validation.default then
		return validation.default
	end
	if validation.one_of then
		return validation.one_of[1]
	end
	local type_string = validation.type
	if type_string == "string" then
		return ""
	elseif type_string == "number" then
		if validation.range then
			return validation.range[1]
		end
		return 0
	elseif type_string == "boolean" then
		return false
	elseif type_string == "table" then
		return {}
	end
	return ""
end

local fill_params
fill_params = function(validations, object)
	if not validations then
		return
	end
	for _, validation in ipairs(validations) do
		local value = get_default_value(validation)
		object[validation[1]] = value
		if validation.type == "table" then
			fill_params(validation.validations, value)
		end
	end
end

Controller.get_body_params = function(self, method)
	local validations = self.validations[method]
	if not validations then
		return {}
	end
	local params = {}
	for _, validation in ipairs(validations) do
		if validation.body and not validation.is_file then
			local value = get_default_value(validation)
			params[validation[1]] = value
			if validation.type == "table" then
				fill_params(validation.validations, value)
			end
		end
	end
	return params
end

Controller.get_query_params = function(self, method)
	local validations = self.validations[method]
	if not validations then
		return {}
	end
	local params = {}
	for _, validation in ipairs(validations) do
		if not validation.body then
			params[validation[1]] = get_default_value(validation)
		end
	end
	return params
end

Controller.get_body_validations = function(self, method)
	local validations = self.validations[method]
	if not validations then
		return {}
	end
	local body_validations = {}
	for _, param in ipairs(validations) do
		if param.body then
			table.insert(body_validations, param)
		end
	end
	return body_validations
end

Controller.get_query_validations = function(self, method)
	local validations = self.validations[method]
	if not validations then
		return {}
	end
	local query_validations = {}
	for _, param in ipairs(validations) do
		if not param.body then
			table.insert(query_validations, param)
		end
	end
	return query_validations
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
