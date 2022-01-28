local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context.user.is_banned
end

rule.effect = "deny"

return rule
