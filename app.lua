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

validate.validate_functions.body = function(input) return true, "" end
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
	local data = response[data_name]
	if not data then
		return
	end
	if data[1] then
		if type(data[1]) == "table" then
			return "array_of_objects"
		end
		return "array"
	end
	return "object"
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
		local errors = {}
		local validations = controller.validations[method]
		if validations then
			errors = recursive_validate(self.params, validations)
		end
		local context = get_context(self, controller, self.params.methods or html)
		local methods
		if self.params.methods then
			methods = get_permited_methods(self, controller)
		end
		local code, response = 403, {}
		if not controller[method] then
			code, response = 405, {}
		elseif #errors > 0 then
			code, response = 400, {errors = errors}
		elseif controller:check_access(self, method) or methods and includes(methods, method) then
			code, response = controller[method](self)
			response.total = tonumber(response.total)
			response.filtered = tonumber(response.filtered)
		end
		response.methods = methods
		if self.params.params then
			response.params = self.params
		end
		if not html then
			return {json = response, status = code}
		end
		self.data_name = get_data_name(response)
		self.data_type = get_data_type(response, self.data_name)
		self.data = response[self.data_name]
		self.code = code
		self.response = response
		self.controller = controller
		self.methods = get_permited_methods(self, controller)
		return {render = "index", status = code}
	end)
	json_respond_to("/ac" .. controller.path, function(self)
		tonumber_params(self, controller)
		local context = get_context(self, controller, true)
		return {json = {methods = get_permited_methods(self, controller)}, status = 200}
	end)
end

local function route_api_debug(controller)
	return json_respond_to("/api_debug" .. controller.path, function(self)
		tonumber_params(self, controller)
		local context = get_context(self, controller)
		local method = self.req.method
		if controller[method] then
			local code, response = controller[method](self)
			return {json = response, status = code}
		else
			return {json = {}, status = 200}
		end
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
			local code, response = controller.GET(self)
			return {json = datatable.response(response, self), status = code}
		else
			return {json = {decision = context.decision}, status = 200}
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
		route_api_debug(controller)
		route_datatables(controller, name)
	end
end

app:match("/api/create_db", function(self)
	local db = require("db")
	db.drop()
	db.create()

	local admin = {
		name = "admin",
		tag = "0000",
		email = "admin@admin",
		password = "password"
	}

	local lapisdb = require("lapis.db")
	local bcrypt = require("bcrypt")

	local Users = require("models.users")
	local Communities = require("models.communities")
	local Leaderboards = require("models.leaderboards")
	local Community_users = require("models.community_users")
	local Community_leaderboards = require("models.community_leaderboards")
	local Difftables = require("models.difftables")
	local Roles = require("enums.roles")
	local leaderboard_c = require("controllers.leaderboard")

	local user = Users:create({
		name = admin.name,
		tag = admin.tag,
		email = admin.email,
		password = bcrypt.digest(admin.password, 5),
		latest_activity = 0,
		created_at = 0,
		description = "",
	})

	local community = Communities:create({
		name = "Community",
		alias = "???",
		link = "https://soundsphere.xyz",
		short_description = "Short descr.",
		description = "Long description",
		banner = "",
		is_public = true,
	})

	Community_users:create({
		community_id = community.id,
		user_id = user.id,
		sender_id = user.id,
		role = Roles:for_db("creator"),
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	local difftable = Difftables:create({
		name = "Difficulty table",
		link = "https://soundsphere.xyz",
		description = "Description",
		owner_community_id = community.id,
	})

	local leaderboard = Leaderboards:create({
		name = "Leaderboard",
		description = "Description",
		banner = "",
	})

	Community_leaderboards:create({
		community_id = community.id,
		leaderboard_id = leaderboard.id,
		is_owner = true,
		sender_id = user.id,
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	leaderboard_c.update_inputmodes(leaderboard.id, {"10key"})
	leaderboard_c.update_difftables(leaderboard.id, {difftable})
	leaderboard_c.update_modifiers(leaderboard.id, {{name = "Automap", value = "4 to 10", rule = "required"}})
end)

function app:handle_error(err, trace)
	if secret.custom_error_page then
		return {json = {
			err = err,
			trace = trace,
		}, status = 500}
	else
		return lapis.Application.handle_error(self, err, trace)
	end
end

app:match("/api/test_session", json_params(function(self)
	self.session.user = "semyon422"
	return {json = self.session}
end))

return app
