local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local user = request.context.session_user
	return #user.communities:select({role = "creator"}) == 0
end

rule.effect = "permit"

return rule
