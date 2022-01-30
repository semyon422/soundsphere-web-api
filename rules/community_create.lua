local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local user = request.context.session_user

	local is_public = request.params.community.is_public
	if not user.roles.donator and not is_public then
		return false
	end

	return #user.communities:select({role = "creator", is_public = is_public}) < 1
end

rule.effect = "permit"

return rule
