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
pep.policy_sets = require("policy_sets")

local token_auth = require("token_auth")
local basic_auth = require("basic_auth")

local function route_api(path, name, controller)
	return app.route(
		{
			path = path
		},
		function(req, res, go)
			token_auth(req)
			basic_auth(req)
			res.code = 200
			local permit, context = pep:check(name, req)
			res.body = util.to_json({decision = context.decision})
			if not permit then
				return go()
			end
			if controller[req.method] then
				controller[req.method](req, res)
			end
			return go()
		end
	)
end

local function route_ac(path, name)
	return app.route(
		{
			path = path,
			method = "GET"
		},
		function(req, res, go)
			token_auth(req)
			basic_auth(req)
			res.code = 200
			if not req.query or not req.query.method then
				return
			end
			local query_method = req.query.method
			local methods = type(query_method) == "string" and {query_method} or query_method
			local decisions = {}
			for _, method in ipairs(methods) do
				req.method = method
				local permit, context = pep:check(name, req)
				decisions[method] = context.decision
			end
			res.body = util.to_json({decisions = decisions})
			return go()
		end
	)
end

-- permit, deny, not_applicable, indeterminate

local endpoints = require("endpoints")

for _, endpoint in ipairs(endpoints) do
	local controller = require("controllers." .. endpoint.name)
	route_api("/api" .. endpoint.path, endpoint.name, controller)
	route_ac("/ac" .. endpoint.path, endpoint.name)
end

app.start()

local tests = require("tests")
tests.start()
