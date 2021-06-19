local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "leaderboard_table"
end

policy_set.policies = {
	require("policies.leaderboard.table.delete"),
	require("policies.leaderboard.table.put"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

policy_set.context_loaders = {
    require("context_loaders.leaderboard"),
    require("context_loaders.table"),
}

return policy_set
