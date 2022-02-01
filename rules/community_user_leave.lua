local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local session_user = request.context.session_user

	local community_users = session_user.communities:select({
		community_id = assert(request.params.community_id),
	})
	if #community_users == 0 or community_users[1].role == "creator" then
		return false
	end

	return true
end

rule.effect = "permit"

return rule
