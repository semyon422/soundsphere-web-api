local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local latest_score = request.context.session_user.latest_score
	if not latest_score then
		return true
	end
	return os.time() - latest_score.created_at >= 30
end

rule.effect = "permit"

return rule
