local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local user = request.context.session_user
	return #user.communities:select({
		role = assert(self.any_community_role),
	}) > 0
end

rule.effect = "permit"

return rule
