local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "domain"
end

policy_set.policies = {
	require("policies.domain.get"),
	require("policies.domain.patch"),
	require("policies.domain.delete"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

policy_set.context_loaders = {
    require("context_loaders.domain"),
}

return policy_set
