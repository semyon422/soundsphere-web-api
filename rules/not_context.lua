local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local not_context = assert(self.not_context)
	if type(not_context) == "string" then
		return request.context[not_context]
	end
	for _, v in ipairs(not_context) do
		if request.context[v] then
			return false
		end
	end
	return true
end

rule.effect = "permit"

return rule
