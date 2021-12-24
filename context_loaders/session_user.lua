local Users = require("models.users")

return function(self)
	if self.context.user then return true end
	local user_id = self.session.user_id
	if user_id then
		self.context.session_user = Users:find(user_id)
	end
	return self.context.session_user
end
