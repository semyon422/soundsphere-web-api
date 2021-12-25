local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	return request.context.loaded[request.req.method]
end

rule.effect = "permit"

return rule