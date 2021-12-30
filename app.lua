local lapis = require("lapis")
local util = require("lapis.util")
local respond_to = require("lapis.application").respond_to
local json_params = require("util.json_params")
local validate = require("lapis.validate")
local app_helpers = require("lapis.application")
local app = lapis.Application()

local secret = require("secret")

local token_auth = require("auth.token")
local basic_auth = require("auth.basic")

app:enable("etlua")
app.layout = require("views.layout")

validate.validate_functions.param_type = function(input) return true, "" end
validate.validate_functions.no_value = function(input, validations) return true, "" end
validate.validate_functions.validations = function(input, validations) return true, "" end
validate.validate_functions.default = function(input, validations) return true, "" end

validate.validate_functions.range = function(v, ...)
	local range = {...}
	local message = "%s must be in [" .. table.concat(range, ", ") .. "]"
	if v < range[1] or v > (range[2] or math.huge) then
		return false, message
	end
	if not range[3] then
		return true
	end
	local i = (v - range[1]) / range[3]
	return tostring(i) == tostring(math.floor(i)), message
end

local function copy_table(src, dst)
	if not src then
		return
	end
	for k, v in pairs(src) do
		dst[k] = v
	end
end

local function append_table(src, dst)
	if not src then
		return
	end
	for _, v in pairs(src) do
		dst[#dst + 1] = v
	end
end

local function fix_types(object, validations)
	for _, validation in ipairs(validations) do
		local key = validation[1]
		local value = object[key]
		local vtype = validation.type
		if vtype == "string" then
			object[key] = value ~= nil and tostring(value) or ""
		elseif vtype == "number" then
			object[key] = tonumber(value)
		elseif vtype == "boolean" then
			if value == 1 or value == "1" or value == true or value == "true" then
				object[key] = true
			elseif value == 0 or value == "0" or value == false or value == "false" then
				object[key] = false
			else
				object[key] = nil
			end
		end
	end	
end
local function recursive_validate(object, validations)
	local validate = validate.validate
	local errors = {}
	fix_types(object, validations)
	append_table(validate(object, validations), errors)
	for _, validation in ipairs(validations) do
		if validation.validations then
			local sub_object = object[validation[1]]
			if type(sub_object) ~= "table" then
				sub_object = {}
			end
			fix_types(sub_object, validation.validations)
			append_table(validate(sub_object, validation.validations), errors)
		end
	end
	return errors
end

local function get_context(self, controller, all_methods)
	copy_table(basic_auth(self.req.headers.Authorization), self.params)
	copy_table(token_auth(self.req.headers.Authorization), self.session)

	self.context = {
		ip = self.req.headers["X-Real-IP"],
		loaded = {},
	}

	if all_methods then
		for _, method in ipairs(controller.methods) do
			controller:load_context(self, method)
		end
	else
		controller:load_context(self)
	end

	return self.context
end

local function json_respond_to(path, respond)
	return app:match(path, json_params(respond_to({
		GET = respond,
		POST = respond,
		PUT = respond,
		PATCH = respond,
		DELETE = respond,
	})))
end

local function json_respond_to_name(name, path, respond)
	return app:match(name, path, json_params(respond_to({
		GET = respond,
		POST = respond,
		PUT = respond,
		PATCH = respond,
		DELETE = respond,
	})))
end

local function get_permited_methods(self, controller)
	local methods = {}
	for _, method in ipairs(controller.methods) do
		local req_method = self.req.method
		self.req.method = method
		if controller:check_access(self, method) then
			table.insert(methods, method)
		end
		self.req.method = req_method
	end
	return methods
end

local function includes(list, item)
	for _, included_item in ipairs(list) do
		if item == included_item then
			return true
		end
	end
end

local function get_data_name(response)
	if not response then
		return
	end
	local names = {}
	for key, value in pairs(response) do
		if type(value) == "table" then
			table.insert(names, key)
		end
	end
	table.sort(names)
	return names[1]
end

local function get_data_type(response, data_name)
	if not response then
		return
	end
	local data = response[data_name]
	if not data then
		return
	end
	if data[1] then
		if type(data[1]) == "table" then
			return "array_of_objects"
		end
		return "array"
	elseif next(data) then
		return "object"
	end
end

local function tonumber_params(self, controller)
	local params = self.params
	for key in controller.path:gmatch(":([^/]+)%[%%d%]") do
		params[key] = tonumber(params[key])
	end
	params.per_page = tonumber(params.per_page)
	params.page_num = tonumber(params.page_num)
end

local function route_api(controller, html)
	local prefix = not html and "/api" or "/api/html"
	local name_prefix = not html and "" or "html."
	json_respond_to_name(name_prefix .. controller.name, prefix .. controller.path, function(self)
		local method = self.req.method
		tonumber_params(self, controller)
		local errors
		local validations = controller.validations[method]
		if validations then
			errors = recursive_validate(self.params, validations)
		end
		local context = get_context(self, controller, self.params.methods or html)
		local methods
		if self.params.methods then
			methods = get_permited_methods(self, controller)
		end
		local response = {status = 403}
		if not controller[method] then
			response.status = 405
		elseif errors and #errors > 0 then
			response.status = 400
			response.errors = errors
		elseif methods and includes(methods, method) or controller:check_access(self, method) then
			response = controller[method](self)
			response.status = response.status or 200
		end
		response.methods = methods
		if self.params.params then
			response.params = self.params
		end
		if not html then
			return response
		end
		local json_response = response.json
		self.data_name = get_data_name(json_response)
		self.data_type = get_data_type(json_response, self.data_name)
		self.data = json_response and json_response[self.data_name] or {}
		self.response = response
		self.controller = controller
		self.methods = methods or get_permited_methods(self, controller)
		return {render = "index", status = response.status}
	end)
	json_respond_to("/ac" .. controller.path, function(self)
		tonumber_params(self, controller)
		local context = get_context(self, controller, true)
		return {json = {methods = get_permited_methods(self, controller)}, status = 200}
	end)
end

local function route_datatables(controller, name)
	local ok, datatable = pcall(require, "datatables." .. name)
	if not ok then
		return
	end
	return json_respond_to("/dt" .. controller.path, function(self)
		tonumber_params(self, controller)
		local context = get_context(self, controller)
		if controller:check_access(self, "GET") then
			local params = self.params
			if tonumber(params.length) == -1 then
				params.get_all = true
			else
				params.page_num = math.floor((params.start or 0) / (params.length or 1)) + 1
				params.per_page = params.length
			end
			if type(params.search) == "table" then
				params.search = params.search.value
			end
			if datatable.params then
				datatable.params(self)
			end
			local response = controller.GET(self)
			response.json = datatable.response(response.json or {}, self)
			return response
		else
			return {json = {decision = context.decision}, status = 403}
		end
	end)
end

-- permit, deny, not_applicable, indeterminate

local autoload = require("lapis.util").autoload
local controllers = autoload("controllers")

local endpoints = require("endpoints")

for _, name in ipairs(endpoints) do
	local controller = controllers[name]
	controller.level = select(2, controller.path:gsub("/", ""))
	controller.name = name
end
for _, name in ipairs(endpoints) do
	local controller = controllers[name]
	controller.children = {}
	for _, child_name in ipairs(endpoints) do
		local child_controller = controllers[child_name]
		if
			child_controller.level == controller.level + 1 and
			child_controller.path:find(controller.path, 1, true)
		then
			child_controller.parent = controller
			table.insert(controller.children, child_controller)
		end
	end
end

local names, paths = {}, {}
for _, name in ipairs(endpoints) do
	names[name] = names[name] and error(name) or name
	local controller = controllers[name]
	local path = controller.path
	if path then
		names[path] = names[path] and error(names[path] .. " " .. name .. " " .. path) or name
		route_api(controller)
		route_api(controller, true)
		route_datatables(controller, name)
	end
end

function app:handle_error(err, trace)
	if secret.custom_error_page then
		return {status = 500, json = {
			err = err,
			trace = trace,
		}}
	else
		return lapis.Application.handle_error(self, err, trace)
	end
end

return app
