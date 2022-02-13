local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local user = request.context.session_user
	local owner_community_id = request.context.leaderboard.owner_community_id
	return #user.communities:select({
		community_id = owner_community_id,
		role = assert(self.leaderboard_role),
	}) > 0
end

rule.effect = "permit"

return rule
