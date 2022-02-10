local Community_users = require("models.community_users")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("community_user", function(self)
	local community_id = self.params.community_id
	local user_id = self.params.user_id
	if community_id and user_id then
		return Community_users:find({
			community_id = community_id,
			user_id = user_id,
		})
	end
end)
