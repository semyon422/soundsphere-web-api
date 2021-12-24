local Users = require("models.users")

return function(self)
	if self.context.user then return true end
	local user_id = self.params.user_id
	if user_id then
		self.context.user = Users:find(user_id)
	end
	return self.context.user
end
