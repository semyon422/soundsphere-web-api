local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local context = request.context
	local params = request.params
	local roles = context.user.roles

	if
		not roles.donator and
		(
			params.user.name ~= context.user.name or
			params.user.banner ~= context.user.banner or
			params.user.color_left ~= context.user.color_left or
			params.user.color_right ~= context.user.color_right
		)
	then
		return false
	end

	return true
end

rule.effect = "permit"

return rule
