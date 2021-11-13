local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context.session_user.roles.creator.root
end

rule.effect = "permit"

return rule
