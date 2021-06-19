local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "group"
end

policy_set.policies = {
	require("policies.group.get"),
	require("policies.group.patch"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

policy_set.context_loaders = {
    require("context_loaders.group"),
}

return policy_set
