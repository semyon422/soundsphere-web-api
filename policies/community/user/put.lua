local Policy = require("abac.Policy")

local policy = Policy:new()

function policy:target(context)
	return context.req.method == "PUT"
end

policy.rules = {
	require("rules.community_admin")
}

policy.rule_combine_algorithm = require("abac.combine.permit_all_or_deny")

return policy
