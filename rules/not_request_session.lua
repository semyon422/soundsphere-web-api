local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context.request_session.id ~= request.context.session.id
end

rule.effect = "permit"

return rule