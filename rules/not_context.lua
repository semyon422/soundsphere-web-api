local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return not request.context[assert(self.not_context)]
end

rule.effect = "permit"

return rule
