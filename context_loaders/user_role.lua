local User_roles = require("models.user_roles")
local Roles = require("enums.roles")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("user_role", function(self)
	local user_id = self.params.user_id
	local role = self.params.role
	if user_id and role then
		return User_roles:find({
			user_id = user_id,
			role = Roles:for_db(role),
		})
	end
end)
