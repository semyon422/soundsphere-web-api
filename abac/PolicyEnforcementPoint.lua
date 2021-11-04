local first_applicable = require("abac.combine.first_applicable")

local PolicyEnforcementPoint = {}

function PolicyEnforcementPoint:new()
	return setmetatable({}, {__index = PolicyEnforcementPoint})
end

function PolicyEnforcementPoint:check(request, name, method)
	local policies = require("policies." .. name)[method] or {}
	local decision
	for i = 0, #policies - 1 do
		local policy = policies[i + 1]
		local policy_decision
		for j = 0, #policy.rules - 1 do
			local rule = policy.rules[j + 1]
			local rule_decision = rule:evaluate(request)
			policy_decision = policy_decision and policy.combine(policy_decision, rule_decision) or rule_decision
		end
		decision = decision and first_applicable(decision, policy_decision) or policy_decision
	end

	return decision == "permit"
end

return PolicyEnforcementPoint
