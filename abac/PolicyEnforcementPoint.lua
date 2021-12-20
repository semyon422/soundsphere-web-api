local first_applicable = require("abac.combine.first_applicable")
local permit_all_or_deny = require("abac.combine.permit_all_or_deny")
local autoload = require("lapis.util").autoload
local auto_rules = autoload("rules")
local auto_policies = autoload("policies")
local combines = autoload("abac.combine")

local PolicyEnforcementPoint = {}

function PolicyEnforcementPoint:check(request, policies)
	if not policies then
		return false
	end
	if type(policies) == "string" then
		policies = auto_policies[policies]
	end
	local decision
	for i = 1, #policies do
		local policy = policies[i]
		if type(policy) == "string" then
			policy = auto_policies[policy]
		end
		local policy_decision
		for j = 1, #policy do
			local rule = policy[j]
			if type(rule) == "string" then
				rule = auto_rules[rule]
			end
			local rule_decision = rule:evaluate(request)
			local combine = policy.combine or permit_all_or_deny
			if type(combine) == "string" then
				combine = combines[combine]
			end
			policy_decision = policy_decision and combine(policy_decision, rule_decision) or rule_decision
		end
		decision = decision and first_applicable(decision, policy_decision) or policy_decision
	end

	return decision == "permit"
end

return PolicyEnforcementPoint
