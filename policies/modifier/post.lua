local Policy = require("abac.Policy")

local policy = Policy:new()

function policy:target(context)
	return context.req.method == "POST"
end

policy.rules = {
	require("rules.creator_root")
}

policy.rule_combine_algorithm = require("abac.combine.permit_all_or_deny")

policy.context_loaders = {
    require("context_loaders.token_user"),
    require("context_loaders.user_roles"),
}

return policy
