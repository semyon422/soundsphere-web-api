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
	app:match(path, json_params(respond_to({
		GET = respond,
		POST = respond,
		PUT = respond,
		PATCH = respond,
		DELETE = respond,
	})))
end

local function route_api(path, endpoint, controller)
	local function respond(self)
		local context = get_context(endpoint, self)
		local method = self.req.method
		local permit = pep:check(context, endpoint.name, method)
		if permit and controller[method] then
			local code, response = controller[method](context.params, context)
			return {json = response, status = code}
		else
			return {json = {decision = context.decision}, status = 200}
		end
	end
	json_respond_to(path, respond)
end

local function route_api_debug(path, endpoint, controller)
	local function respond(self)
		local context = get_context(endpoint, self)
		local method = self.req.method
		if controller[method] then
			local code, response = controller[method](context.params, context)
			return {json = response, status = code}
		else
			return {json = {}, status = 200}
		end
	end
	json_respond_to(path, respond)
end

local function route_datatables(path, endpoint, controller, datatable)
	local function respond(self)
		local context = get_context(endpoint, self)
		local permit = pep:check(context, endpoint.name, "GET")
		if permit and controller.GET then
			local code, response = controller.GET(datatable.params(context.params), context)
			return {json = datatable.response(response, context.params), status = code}
		else
			return {json = {decision = context.decision}, status = 200}
		end
	end
	json_respond_to(path, respond)
end

local function route_ac(path, endpoint)
	local function respond(self)
		if not self.params.methods then return end
		local context = get_context(endpoint, self)
		local decisions = {}
		for method in self.params.methods:gmatch("([A-Z]+)") do
			local permit = pep:check(context, endpoint.name, method)
			decisions[method] = context.decision
		end
		return {json = {decisions = decisions}, status = 200}
	end
	json_respond_to(path, respond)
end

-- permit, deny, not_applicable, indeterminate

local endpoints = require("endpoints")

for _, endpoint in ipairs(endpoints) do
	local controller = require("controllers." .. endpoint.name)
	route_api("/api" .. endpoint.path, endpoint, controller)
	route_api_debug("/api_debug" .. endpoint.path, endpoint, controller)
	route_ac("/ac" .. endpoint.path, endpoint)

	local ok, datatable = pcall(require, "datatables." .. endpoint.name)
	if ok then
		route_datatables("/dt" .. endpoint.path, endpoint, controller, datatable)
	end
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
