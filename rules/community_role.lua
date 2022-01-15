local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local user = request.context.session_user
	return #user.communities:select({
		community_id = assert(request.params.community_id),
		role = assert(self.community_role),
	}) > 0
end

rule.effect = "permit"

return rule
