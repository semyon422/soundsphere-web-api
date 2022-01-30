local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local context = request.context
	local params = request.params
	local roles = context.user.roles

	if params.user.name ~= context.user.name and not roles.donator then
		return false
	end

	return true
end

rule.effect = "permit"

return rule
