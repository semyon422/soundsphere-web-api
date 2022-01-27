local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local bypass_key = request.context.bypass_key
	local session_user = request.context.session_user
	return bypass_key.user_id == session_user.id
end

rule.effect = "permit"

return rule
