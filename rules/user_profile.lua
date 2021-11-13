local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return tonumber(request.context.session_user.id) == tonumber(request.params.user_id)
end

rule.effect = "permit"

return rule
