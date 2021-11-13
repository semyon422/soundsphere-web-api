local first_applicable = require("abac.combine.first_applicable")

local PolicyEnforcementPoint = {}

function PolicyEnforcementPoint:new()
	return setmetatable({}, {__index = PolicyEnforcementPoint})
end

function PolicyEnforcementPoint:check(request, controller, method)
	local policies = controller.policies[method] or {}
	local decision
	for i = 1, #policies do
		local policy = policies[i]
		local policy_decision
		for j = 1, #policy.rules do
			local rule = policy.rules[j]
			local rule_decision = rule:evaluate(request)
			policy_decision = policy_decision and policy.combine(policy_decision, rule_decision) or rule_decision
		end
		decision = decision and first_applicable(decision, policy_decision) or policy_decision
	end

	return decision == "permit"
end

return PolicyEnforcementPoint
