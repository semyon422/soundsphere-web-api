local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context.token_user.roles.donator
end

rule.effect = "permit"

return rule
