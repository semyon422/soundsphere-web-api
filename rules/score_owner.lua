local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context.score.user_id == request.context.session_user.id
end

rule.effect = "permit"

return rule
