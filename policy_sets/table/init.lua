local PolicySet = require("abac.PolicySet")

local policy_set = PolicySet:new()

function policy_set:target(context)
	return context.name == "table"
end

policy_set.policies = {
	require("policies.table.delete"),
	require("policies.table.get"),
	require("policies.table.patch"),
}

policy_set.policy_combine_algorithm = require("abac.combine.only_one_applicable")

policy_set.context_loaders = {
    require("context_loaders.table"),
}

return policy_set