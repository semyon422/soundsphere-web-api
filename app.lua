local lapis = require("lapis")
local util = require("lapis.util")
local respond_to = require("lapis.application").respond_to
local json_params = require("lapis.application").json_params
local app = lapis.Application()

local PolicyEnforcementPoint = require("abac.PolicyEnforcementPoint")

local pep = PolicyEnforcementPoint:new()

local token_auth = require("auth.token")
local basic_auth = require("auth.basic")

local function get_context(endpoint, self)
	local context = {
		params = self.params,
		basic = basic_auth(self.req),
		token = token_auth(self.req),
	}

	if endpoint.context then
		for _, name in ipairs(endpoint.context) do
			local context_loader = require("context_loaders." .. name)
			context_loader:load_context(context)
		end
	end

	return context
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

local function get_permited_methods(endpoint, context)
	local methods = {}
	for _, method in ipairs(endpoint.methods) do
		if pep:check(context, endpoint.name, method) then
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
		local context = get_context(endpoint, self)
		local methods = get_permited_methods(endpoint, context)
		local method = self.req.method
		local code, response
		if includes(methods, method) and controller[method] then
			code, response = controller[method](context.params, context)
		else
			code, response = 200, {decision = context.decision}
		end
		response.methods = methods
		return {json = response, status = code}
	end)
end

local function route_api_debug(endpoint, controller)
	return json_respond_to("/api_debug" .. endpoint.path, function(self)
		local context = get_context(endpoint, self)
		local method = self.req.method
		if controller[method] then
			local code, response = controller[method](context.params, context)
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
		local context = get_context(endpoint, self)
		if pep:check(context, endpoint.name, "GET") and controller.GET then
			local code, response = controller.GET(datatable.params(context.params), context)
			return {json = datatable.response(response, context.params), status = code}
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

app:match("/create_db", function(self)
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
	lapisdb.query(
		"INSERT INTO `users` (`name`, `tag`, `email`, `password`) VALUES (?, ?, ?, ?);",
		admin.name,
		admin.tag,
		admin.email,
		bcrypt.digest(admin.password, 5)
	)
end)

return app
