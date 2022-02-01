local Rule = require("abac.Rule")
local Roles = require("enums.roles")

local rule = Rule:new()

function rule:condition(request)
	local session_user = request.context.session_user
	local user = request.context.user

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

	community_users = user.communities:select({
		community_id = assert(request.params.community_id),
		accepted = false,
	})
	if #community_users == 0 then
		return false
	end

	return true
end

rule.effect = "permit"

return rule
