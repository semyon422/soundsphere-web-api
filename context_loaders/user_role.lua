local User_roles = require("models.user_roles")
local Roles = require("enums.roles")

return function(self)
	if self.context.user_role then return true end
	local user_id = self.params.user_id
	local role = self.params.role
	if user_id and role then
		self.context.user_role = Users:find({
			user_id = user_id,
			role = Roles:for_db(role),
		})
	end
	return self.context.user_role
end
