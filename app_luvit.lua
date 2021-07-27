local app = require("weblit-app")
local util = require("lapis.util")
package.loaded.http = require("http")

app.bind({
	host = "0.0.0.0",
	port = 8081
})

app.use(require("weblit-logger"))
app.use(require("weblit-auto-headers"))
app.use(require("weblit-etag-cache"))

local PolicyEnforcementPoint = require("abac.PolicyEnforcementPoint")

local pep = PolicyEnforcementPoint:new()

local token_auth = require("auth.token")
local basic_auth = require("auth.basic")

local function get_params(req)
	local t = {}
	for k, v in pairs(req.params) do t[k] = v end
	if req.query then
		for k, v in pairs(req.query) do t[k] = v end
	end
	if req.headers["Content-Type"] and req.headers["Content-Type"]:lower() == "application/json" then
		local json_body = util.from_json(req.body)
		for k, v in pairs(json_body) do t[k] = v end
	end
	return t
end

local function get_context(endpoint, req)
	local context = {
		params = get_params(req),
		basic = basic_auth(req),
		token = token_auth(req),
	}

	if endpoint.context then
		for _, name in ipairs(endpoint.context) do
			local context_loader = require("context_loaders." .. name)
			context_loader:load_context(context)
		end
	end

	return context
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

local function route_api(path, endpoint, controller)
	return app.route({path = path}, function(req, res, go)
		local context = get_context(endpoint, req)
		local methods = get_permited_methods(endpoint, context)
		local method = req.method
		local code, response
		if includes(methods, method) and controller[method] then
			code, response = controller[method](context.params, context)
		else
			code, response = 200, {decision = context.decision}
		end
		response.methods = methods
		res.code = code
		res.body = util.to_json(response)
		res.headers["Content-Type"] = "application/json"
		return go()
	end)
end

local function route_api_debug(path, endpoint, controller)
	return app.route({path = path}, function(req, res, go)
		local context = get_context(endpoint, req)
		if controller[req.method] then
			local code, response = controller[req.method](context.params, context)
			res.code = code
			res.body = util.to_json(response)
		else
			res.code = 200
			res.body = "{}"
		end
		res.headers["Content-Type"] = "application/json"
		return go()
	end)
end

local function route_datatables(path, endpoint, controller, datatable)
	return app.route({path = path, method = "GET"}, function(req, res, go)
		local context = get_context(endpoint, req)
		local permit = pep:check(context, endpoint.name, req.method)
		if permit and controller.GET then
			local code, response = controller.GET(datatable.params(context.params), context)
			res.code = code
			res.body = util.to_json(datatable.response(response, context.params))
		else
			res.code = 200
			res.body = util.to_json({decision = context.decision})
		end
		res.headers["Content-Type"] = "application/json"
		return go()
	end)
end

-- permit, deny, not_applicable, indeterminate

local endpoints = require("endpoints")

for _, endpoint in ipairs(endpoints) do
	local controller = require("controllers." .. endpoint.name)
	route_api("/api" .. endpoint.path, endpoint, controller)
	route_api_debug("/api_debug" .. endpoint.path, endpoint, controller)

	local ok, datatable = pcall(require, "datatables." .. endpoint.name)
	if ok then
		route_datatables("/dt" .. endpoint.path, endpoint, controller, datatable)
	end
end

app.start()

local tests = require("tests")
tests.start()
