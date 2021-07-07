local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "leaderboard.inputmodes"
end

policy_set.policies = {
	require("policies.leaderboard.inputmodes.get")
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

return policy_set
