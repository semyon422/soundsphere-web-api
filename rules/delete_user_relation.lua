local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context.user_relation.created_at + 3600 * 24 * 7 < os.time()
end

rule.effect = "permit"

return rule
