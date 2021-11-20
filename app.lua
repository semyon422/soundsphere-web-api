local lapis = require("lapis")
local util = require("lapis.util")
local respond_to = require("lapis.application").respond_to
local json_params = require("lapis.application").json_params
local app = lapis.Application()

local PolicyEnforcementPoint = require("abac.PolicyEnforcementPoint")

local pep = PolicyEnforcementPoint:new()

local token_auth = require("auth.token")
local basic_auth = require("auth.basic")

local function get_context(self, endpoint)
	self.context = {
		basic = basic_auth(self.req.headers.Authorization),
		token = token_auth(self.req.headers.Authorization),
		ip = self.req.headers["X-Real-IP"]
	}

	if endpoint.context then
		for _, name in ipairs(endpoint.context) do
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

local function get_permited_methods(self, endpoint)
	local methods = {}
	for _, method in ipairs(endpoint.methods) do
		if pep:check(self, endpoint.name, method) then
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

local function route_api(endpoint, controller)
	return json_respond_to("/api" .. endpoint.path, function(self)
		local context = get_context(self, endpoint)
		local methods = get_permited_methods(self, endpoint)
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
end

local function route_api_debug(endpoint, controller)
	return json_respond_to("/api_debug" .. endpoint.path, function(self)
		local context = get_context(self, endpoint)
		local method = self.req.method
		if controller[method] then
			local code, response = controller[method](self)
			return {json = response, status = code}
		else
			return {json = {}, status = 200}
		end
	end)
end

local function route_datatables(endpoint, controller)
	local ok, datatable = pcall(require, "datatables." .. endpoint.name)
	if not ok then
		return
	end
	return json_respond_to("/dt" .. endpoint.path, function(self)
		local context = get_context(self, endpoint)
		if pep:check(self, endpoint.name, "GET") and controller.GET then
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

local endpoints = require("endpoints")

for _, endpoint in ipairs(endpoints) do
	local controller = require("controllers." .. endpoint.name)
	route_api(endpoint, controller)
	route_api_debug(endpoint, controller)
	route_datatables(endpoint, controller)
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

app:match("/api/test_session", json_params(function(self)
	self.session.user = "semyon422"
	return {json = self.session}
end))

return app
