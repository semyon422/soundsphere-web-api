local Users = require("models.users")

return function(self)
	if self.context.user then return end
	local user_id = self.params.user_id
	if user_id then
		self.context.user = Users:find(user_id)
	end
end
