local Rule = require("abac.Rule")
local Roles = require("enums.roles")

local rule = Rule:new()

local roles = Roles.staff_role_names
function rule:condition(request)
	local session_user = request.context.session_user
	local community_user = request.context.community_user

	local user_role = Roles:to_name(community_user.role)
	local session_user_role
	do
		local community_users = session_user.communities:select({
			community_id = assert(request.params.community_id),
			accepted = true,
		})
		if #community_users == 0 then
			return false
		end
		session_user_role = community_users[1].role
	end

	local session_user_role_index = #roles + 1
	local user_role_index = #roles + 1
	for i, current_role in ipairs(roles) do
		if session_user_role == current_role then
			session_user_role_index = i
		end
		if user_role == current_role then
			user_role_index = i
		end
	end

	return session_user_role_index < user_role_index
end

rule.effect = "permit"

return rule
