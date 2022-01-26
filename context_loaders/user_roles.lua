local Roles = require("enums.roles")
local User_roles = require("models.user_roles")

local function load_roles(user)
	local roles = {}

	local time = os.time()
    local user_roles = User_roles:find_all({user.id}, "user_id")
	for _, user_role in ipairs(user_roles) do
		if user_role.expires_at > time then
			roles[Roles:to_name(user_role.role)] = true
		end
	end

	user.roles = roles
end

return function(self)
	local context = self.context
	if context.user and not context.user.roles then
		load_roles(context.user)
	end
	if context.session_user and not context.session_user.roles then
		load_roles(context.session_user)
	end
	return true
end
