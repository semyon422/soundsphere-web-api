local first_applicable = require("abac.combine.first_applicable")

local PolicyEnforcementPoint = {}

function PolicyEnforcementPoint:new()
	return setmetatable({}, {__index = PolicyEnforcementPoint})
end

function PolicyEnforcementPoint:check(endpoint, req)
	local context = {
		name = endpoint.name,
		req = req
	}

	if endpoint.context then
		for _, name in ipairs(endpoint.context) do
			local context_loader = require("context_loaders." .. name)
			context_loader:load_context(context)
		end
	end

	local policies = require("policies." .. endpoint.name)[req.method]
	local decision
	for i = 0, #policies - 1 do
		local policy = policies[i + 1]
		local policy_decision
		for j = 0, #policy.rules - 1 do
			local rule = policy.rules[j + 1]
			local rule_decision = rule:evaluate(context)
			policy_decision = policy_decision and policy.combine(policy_decision, rule_decision) or rule_decision
		end
		decision = decision and first_applicable(decision, policy_decision) or policy_decision
	end

	context.decision = decision
	return decision == "permit", context
end

return PolicyEnforcementPoint
