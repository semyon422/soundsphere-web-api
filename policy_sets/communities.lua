local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "communities"
end

policy_set.policies = {
	require("policies.communities.get"),
	require("policies.communities.post"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

return policy_set
