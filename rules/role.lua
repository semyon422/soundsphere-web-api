local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local user = request.context.session_user
	return user and user.roles and user.roles[self.role]
end

rule.effect = "permit"

return rule
