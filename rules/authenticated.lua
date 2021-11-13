local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.session.id
end

rule.effect = "permit"

return rule
