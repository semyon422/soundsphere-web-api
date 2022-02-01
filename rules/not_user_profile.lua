local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context.request_session.user_id ~= request.params.user_id
end

rule.effect = "permit"

return rule
