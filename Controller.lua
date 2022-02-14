local pep = require("abac.PolicyEnforcementPoint")
local autoload = require("lapis.util").autoload
local context_loaders = autoload("context_loaders")

local Controller = {}

Controller.new = function(self)
	return setmetatable({
		methods = {},
		context = {},
		policies = {},
		display_policies = {},
		validations = {},
	}, {__index = self})
end

Controller.check_policies = function(self, request, policies)
	request.policies = request.policies or {}
	if not policies then
		return
	end
	local check_policies = request.policies[policies]
	if check_policies ~= nil then
		return check_policies
	end
	check_policies = pep:check(request, policies)
	request.policies[policies] = check_policies
	return check_policies
end

Controller.check_access = function(self, request, method, display)
	request.policies = request.policies or {}
	request.permited_methods = request.permited_methods or {}

	if not self[method] or not request.context.loaded[method] then
		return
	end
	local methods = request.permited_methods

	methods[method] =
		methods[method] or
		(display and self:check_policies(request, self.display_policies[method])) or
		self:check_policies(request, self.policies[method])

	return methods[method]
end

Controller.load_context = function(self, request, method)
	if not self[method] or not self.context[method] then
		request.context.loaded[method] = true
		return
	end
	local loaded = true
	for _, name in ipairs(self.context[method]) do
		local result
		if type(name) == "string" then
			result = context_loaders[name](request)
		elseif type(name) == "function" then
			local status, res = pcall(name, request)
			result = status and res
		elseif type(name) == "table" then
			result = context_loaders[name[1]](request)
			if name.missing then
				result = not result
			elseif name.optional then
				result = true
			end
		end
		loaded = loaded and result
		if not loaded then
			break
		end
	end
	request.context.loaded[method] = not not loaded
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
Controller.get_default_value = function(self, validation)
	return get_default_value(validation)
end

local fill_params
fill_params = function(request, validations, params, disabled, body)
	if not validations then
		return
	end
	for _, validation in ipairs(validations) do
		if (body or validation.param_type == "body") and not validation.is_file then
			local value
			if not disabled or validation.type == "table" then
				value = get_default_value(validation)
			elseif validation.policies and not Controller:check_policies(request, validation.policies) then
				value = true
			end
			params[validation[1]] = value
			if validation.type == "table" then
				fill_params(request, validation.validations, value, disabled, true)
			end
		end
	end
end

Controller.get_params_list = function(self)
	local params = {}
	for key in self.path:gmatch(":([^/^%[]+)") do
		table.insert(params, key)
	end
	return params
end

Controller.get_params_struct = function(self, request, params_type, method, disabled)
	local params = {}
	local validations = self.validations[method]
	if not validations then
		return params
	end
	if params_type == "all" then
		fill_params(request, validations, params, disabled, true)
	elseif params_type == "body" then
		fill_params(request, validations, params, disabled)
	elseif params_type == "query" then
		for _, validation in ipairs(validations) do
			if validation.param_type == "query" or not validation.param_type then
				local value
				if not disabled then
					value = get_default_value(validation)
				elseif validation.policies and not Controller:check_policies(request, validation.policies) then
					value = true
				end
				params[validation[1]] = value
			end
		end
	end
	return params
end

Controller.get_missing_params = function(self, params)
	local missing_params = {}
	for key in self.path:gmatch(":([^/^%[]+)") do
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
