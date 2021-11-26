local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local user = request.context.session_user
	local community_id = tonumber(request.params.community_id)
	return #user.communities:select({community_id = community_id, role = "admin"}) > 0
end

rule.effect = "permit"

return rule
