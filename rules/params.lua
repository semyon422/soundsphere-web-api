local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local params = assert(self.params)
	if type(params) == "string" then
		return request.params[params]
	end
	for _, v in ipairs(params) do
		if not request.params[v] then
			return false
		end
	end
	return true
end

rule.effect = "permit"

return rule
