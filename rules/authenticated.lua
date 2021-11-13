local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.session.id and request.context.session.active == 1
end

rule.effect = "permit"

return rule
