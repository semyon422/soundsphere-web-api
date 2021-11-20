local lapis = require("lapis")
local util = require("lapis.util")
local respond_to = require("lapis.application").respond_to
local json_params = require("lapis.application").json_params
local app = lapis.Application()

local secret = require("secret")

local PolicyEnforcementPoint = require("abac.PolicyEnforcementPoint")

local pep = PolicyEnforcementPoint:new()

local token_auth = require("auth.token")
local basic_auth = require("auth.basic")

local function copy_table(src, dst)
	if not src then
		return
	end
	for k, v in pairs(src) do
		dst[k] = v
	end
end

local function get_context(self, controller)
	copy_table(basic_auth(self.req.headers.Authorization), self.params)
	copy_table(token_auth(self.req.headers.Authorization), self.session)

	self.context = {
		ip = self.req.headers["X-Real-IP"]
	}

	if controller.context then
		for _, name in ipairs(controller.context) do
			local context_loader = require("context_loaders." .. name)
			context_loader:load_context(self)
		end
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

local function get_permited_methods(self, controller)
	local methods = {}
	for _, method in ipairs(controller.methods) do
		if pep:check(self, controller, method) then
			table.insert(methods, method)
		end
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

local function route_api(controller)
	json_respond_to("/api" .. controller.path, function(self)
		local context = get_context(self, controller)
		local methods = get_permited_methods(self, controller)
		local method = self.req.method
		local code, response
		if includes(methods, method) and controller[method] then
			code, response = controller[method](self)
		else
			code, response = 500, {}
		end
		response.methods = methods
		return {json = response, status = code}
	end)
	json_respond_to("/ac" .. controller.path, function(self)
		local context = get_context(self, controller)
		return {json = {methods = get_permited_methods(self, controller)}, status = 200}
	end)
end

local function route_api_debug(controller)
	return json_respond_to("/api_debug" .. controller.path, function(self)
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
		local context = get_context(self, controller)
		if pep:check(self, controller, "GET") and controller.GET then
			self.params.start = self.params.start or 1
			self.params.length = self.params.length or 1
			datatable.params(self)
			local code, response = controller.GET(self)
			return {json = datatable.response(response, self), status = code}
		else
			return {json = {decision = context.decision}, status = 200}
		end
	end)
end

-- permit, deny, not_applicable, indeterminate

local names, paths = {}, {}
for _, name in ipairs(require("endpoints")) do
	names[name] = names[name] and error(name) or name
	local controller = require("controllers." .. name)
	local path = controller.path
	if path then
		names[path] = names[path] and error(names[path] .. " " .. name .. " " .. path) or name
		route_api(controller)
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
	Users:create({
		name = admin.name,
		tag = admin.tag,
		email = admin.email,
		password = bcrypt.digest(admin.password, 5),
		latest_activity = 0,
		creation_time = 0,
		description = "",
	})
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
