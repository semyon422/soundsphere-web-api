local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "community_user"
end

policy_set.policies = {
	require("policies.community.user.delete"),
	require("policies.community.user.put"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

policy_set.context_loaders = {
    require("context_loaders.user"),
    require("context_loaders.user_roles"),
    require("context_loaders.community"),
}

return policy_set
