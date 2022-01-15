local Rule = require("abac.Rule")
local Roles = require("enums.roles")

local rule = Rule:new()

function rule:condition(request)
	local session_user = request.context.session_user

	if request.params.user_id == session_user.id then
		return false
	end

	local community_users = session_user.communities:select({
		community_id = assert(request.params.community_id)
	})
	if #community_users == 0 then
		return false
	end

	local role = community_users[1].role
	local has_staff_role = false
	for _, staff_role in ipairs(Roles.staff_role_names) do
		if staff_role == role then
			has_staff_role = true
		end
	end
	if not has_staff_role then
		return false
	end

	return request.params.invitation
end

rule.effect = "permit"

return rule
