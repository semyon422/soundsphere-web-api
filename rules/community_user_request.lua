local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local session_user = request.context.session_user

	if request.params.user_id ~= session_user.id or request.params.invitation then
		return false
	end

	return
		#session_user.communities:select() < 10 and
		#session_user.communities:select({
			community_id = assert(request.params.community_id),
			accepted = true,
		}) == 0
end

rule.effect = "permit"

return rule
