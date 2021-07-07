local Policy = require("abac.Policy")

local policy = Policy:new()

function policy:target(context)
	return context.req.method == "DELETE"
end

policy.rule_combine_algorithm = require("abac.combine.permit_all_or_deny")

return policy
