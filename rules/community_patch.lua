local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local user = request.context.session_user

	if not user.roles.donator and not request.params.community.is_public then
		return false
	end

	return true
end

rule.effect = "permit"

return rule
