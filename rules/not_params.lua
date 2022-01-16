local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	print(123123)
	local not_params = assert(self.not_params)
	if type(not_params) == "string" then
		print(not request.params[not_params])
		return not request.params[not_params]
	end
	for _, v in ipairs(not_params) do
		if request.params[v] then
			return false
		end
	end
	return true
end

rule.effect = "permit"

return rule
