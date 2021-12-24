local Community_users = require("models.community_users")

return function(self)
	if self.context.community_user then return true end
	local community_id = self.params.community_id
	local user_id = self.params.user_id
	if community_id and user_id then
		self.context.community_user = Community_users:find({
			community_id = community_id,
			user_id = user_id,
		})
	end
	return self.context.community_user
end
