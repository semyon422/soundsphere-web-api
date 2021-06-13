local app = require("weblit-app")

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

local function route(path, name, controller)
	return app.route(
		{
			path = path
		},
		function(req, res, go)
			token_auth(req)
			basic_auth(req)
			res.code = 200
			local permit, context = pep:check(name, req)
			res.body = context.decision
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

-- permit, deny, not_applicable, indeterminate

local endpoints = require("endpoints")

for _, endpoint in ipairs(endpoints) do
	local controller = require("controllers." .. endpoint.name:gsub("_", "."))
	route("/api" .. endpoint.path, endpoint.name, controller)
end

app.start()
