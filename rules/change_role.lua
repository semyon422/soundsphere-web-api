local Rule = require("abac.Rule")
local Roles = require("enums.roles")

local rule = Rule:new()

local roles = Roles.staff_role_names
function rule:condition(request)
	local user_roles = request.context.user.roles
	local session_user_roles = request.context.session_user.roles
	local role = request.params.role

	local role_index = #roles + 1
	for i, current_role in ipairs(roles) do
		if role == current_role then
			role_index = i
			break
		end
	end

	local session_user_role_index = #roles + 1
	for i, current_role in ipairs(roles) do
		if session_user_roles[current_role] then
			session_user_role_index = i
			break
		end
	end

	local user_role_index = #roles + 1
	for i, current_role in ipairs(roles) do
		if user_roles[current_role] then
			user_role_index = i
			break
		end
	end

	return session_user_role_index < role_index and session_user_role_index < user_role_index
end

rule.effect = "permit"

return rule
