local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context[assert(self.context)]
end

rule.effect = "permit"

return rule
