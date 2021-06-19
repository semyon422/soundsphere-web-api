local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "user"
end

policy_set.policies = {
	require("policies.user.delete"),
	require("policies.user.get"),
	require("policies.user.patch"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

policy_set.context_loaders = {
    require("context_loaders.user"),
    require("context_loaders.user_roles"),
}

return policy_set
