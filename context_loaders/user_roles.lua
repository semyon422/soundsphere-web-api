local Roles = require("enums.roles")

local context_loader = {}

local function load_roles(user)
	local roles = {}

    local user_roles = user:get_roles()
	for _, user_role in ipairs(user_roles) do
		local role = Roles:to_name(user_role.role)
		roles[role] = true
	end

	user.roles = roles
end

function context_loader:load_context(request)
	local context = request.context
	if context.user and not context.user.roles then
		load_roles(context.user)
	end
	if context.session_user and not context.session_user.roles then
		load_roles(context.session_user)
	end
end

return context_loader
