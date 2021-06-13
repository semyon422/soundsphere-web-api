local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "group_user"
end

policy_set.policies = {
	require("policies.group.user.delete"),
	require("policies.group.user.put"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

return policy_set
