local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(context)
	return tonumber(context.token_user.id) == tonumber(context.req.params.user_id)
end

rule.effect = "permit"

return rule
