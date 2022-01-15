local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local context = assert(self.context)
	if type(context) == "string" then
		return request.context[context]
	end
	for _, v in ipairs(context) do
		if not request.context[v] then
			return false
		end
	end
	return true
end

rule.effect = "permit"

return rule
