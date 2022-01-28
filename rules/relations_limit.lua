local Rule = require("abac.Rule")

local rule = Rule:new()

function rule:condition(request)
	local session_user = request.context.session_user
	local relationtype = request.params.type

	local user_relations = session_user.relations:select({
		relationtype = relationtype,
	})

	if relationtype == "friend" then
		return #user_relations < 100
	elseif relationtype == "rival" then
		if session_user.roles.donator then
			return #user_relations < 20
		end
		return #user_relations < 0
	end
end

rule.effect = "permit"

return rule
