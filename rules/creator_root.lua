local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(context)
	return context.token_user.roles.creator.root
end

rule.effect = "permit"

return rule
