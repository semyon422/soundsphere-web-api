local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "community.leaderboard"
end

policy_set.policies = {
	require("policies.community.leaderboard.delete"),
	require("policies.community.leaderboard.put"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

policy_set.context_loaders = {
    require("context_loaders.community"),
    require("context_loaders.leaderboard"),
}

return policy_set
