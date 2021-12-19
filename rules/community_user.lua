local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context.community_user
end

rule.effect = "permit"

return rule
