local Leaderboard_users = require("models.leaderboard_users")

return function(self)
	if self.context.leaderboard_user then return true end
	local leaderboard_id = self.params.leaderboard_id
	local user_id = self.params.user_id
	if leaderboard_id and user_id then
		self.context.leaderboard_user = Leaderboard_users:find({
			leaderboard_id = leaderboard_id,
			user_id = user_id,
		})
	end
	return self.context.leaderboard_user
end
