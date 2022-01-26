local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local cs = request.context.request_session
	local rs = request.session
	return
		cs.active and
		cs.id == rs.id and
		cs.user_id == rs.user_id and
		cs.created_at == rs.created_at
end

rule.effect = "permit"

return rule
