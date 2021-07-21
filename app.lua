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
-- pep.policy_sets = require("policy_sets")

local token_auth = require("token_auth")
local basic_auth = require("basic_auth")

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

local function get_context(req)
	return {
		req = req,
		params = get_params(req),
		basic = basic_auth(req),
		token = token_auth(req),
	}
end

local function route_api(path, endpoint, controller)
	return app.route({path = path}, function(req, res, go)
		local context = get_context(req)
		local permit = pep:check(endpoint, context)
		if permit and controller[req.method] then
			local code, response = controller[req.method](context.params, context)
			res.code = code
			res.body = util.to_json(response)
		else
			res.code = 200
			res.body = util.to_json({decision = context.decision})
		end
		res.headers["Content-Type"] = "application/json"
		return go()
	end)
end

local function route_api_debug(path, endpoint, controller)
	return app.route({path = path}, function(req, res, go)
		local context = get_context(req)
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
		local context = get_context(req)
		local permit = pep:check(endpoint, context)
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

local function route_ac(path, endpoint)
	return app.route({path = path, method = "GET"}, function(req, res, go)
		if not req.query or not req.query.method then
			return
		end
		local context = get_context(req)
		local query_method = req.query.method
		local methods = type(query_method) == "string" and {query_method} or query_method
		local decisions = {}
		for _, method in ipairs(methods) do
			req.method = method
			local permit = pep:check(endpoint, context)
			decisions[method] = context.decision
		end
		res.code = 200
		res.body = util.to_json({decisions = decisions})
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
	route_ac("/ac" .. endpoint.path, endpoint)

	local ok, datatable = pcall(require, "datatables." .. endpoint.name)
	if ok then
		route_datatables("/dt" .. endpoint.path, endpoint, controller, datatable)
	end
end

app.start()

local tests = require("tests")
tests.start()
