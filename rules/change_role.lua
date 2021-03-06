local Rule = require("abac.Rule")
local Roles = require("enums.roles")

local rule = Rule:new()

local roles = Roles.staff_role_names
function rule:condition(request)
	local user_roles = request.context.user.roles
	local session_user_roles = request.context.session_user.roles
	local role = request.params.role

	local is_staff_role = false
	local is_staff_user = false

	for i, current_role in ipairs(roles) do
		if role == current_role then
			is_staff_role = true
			break
		end
	end

	local session_user_role_index = #roles + 1
	for i, current_role in ipairs(roles) do
		if session_user_roles[current_role] then
			is_staff_user = true
			break
		end
	end

	return not is_staff_role and is_staff_user
end

rule.effect = "permit"

return rule
