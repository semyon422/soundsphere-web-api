local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "leaderboard.user"
end

policy_set.policies = {
	require("policies.leaderboard.user.delete"),
	require("policies.leaderboard.user.put"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

return policy_set
