local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "user.statistics"
end

policy_set.policies = {
	require("policies.user.statistics.get")
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

policy_set.context_loaders = {
    require("context_loaders.user"),
    -- require("context_loaders.user_statistics"),
}

return policy_set
