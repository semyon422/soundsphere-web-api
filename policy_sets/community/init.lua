local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "community"
end

policy_set.policies = {
	require("policies.community.get"),
	require("policies.community.patch"),
	require("policies.community.delete"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

return policy_set
