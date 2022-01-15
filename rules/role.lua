local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context.session_user.roles[self.role]
end

rule.effect = "permit"

return rule
