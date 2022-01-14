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

Controller.get_params_list = function(self, params_type, method)
	local params = {}
	if params_type == "path" then
		for key in self.path:gmatch(":([^/^%[]+)") do
			table.insert(params, key)
		end
		return params
	end
	local validations = self.validations[method]
	if not validations then
		return params
	end
	if params_type == "body" then
		for _, validation in ipairs(validations) do
			if validation.param_type == "body" and not validation.is_file then
				table.insert(params, validation[1])
			end
		end
	elseif params_type == "query" then
		for _, validation in ipairs(validations) do
			if validation.param_type == "query" or not validation.param_type then
				table.insert(params, validation[1])
			end
		end
	end
	return params
end

Controller.get_params_struct = function(self, params_type, method)
	local params = {}
	if params_type == "path" then
		local validations = self.validations.path
		local path_validations = {}
		for _, validation in ipairs(validations or {}) do
			if validation.param_type == "path" then
				local value = get_default_value(validation)
				path_validations[validation[1]] = value
			end
		end
		for key in self.path:gmatch(":([^/^%[]+)") do
			params[key] = path_validations[key] or ""
		end
		return params
	end
	local validations = self.validations[method]
	if not validations then
		return params
	end
	if params_type == "body" then
		for _, validation in ipairs(validations) do
			if validation.param_type == "body" and not validation.is_file then
				local value = get_default_value(validation)
				params[validation[1]] = value
				if validation.type == "table" then
					fill_params(validation.validations, value)
				end
			end
		end
	elseif params_type == "query" then
		for _, validation in ipairs(validations) do
			if validation.param_type == "query" or not validation.param_type then
				params[validation[1]] = get_default_value(validation)
			end
		end
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

Controller.get_validations = function(self, params_type, method, map)
	if params_type == "path" then
		method = "path"
	end
	local validations = self.validations[method]
	if not validations then
		return {}
	end
	local found_validations = {}
	for _, validations in ipairs(validations) do
		if validations.param_type == params_type or not validations.param_type and params_type == "query" then
			if not map then
				table.insert(found_validations, validations)
			else
				found_validations[validations[1]] = validations
			end
		end
	end
	return found_validations
end

return Controller
