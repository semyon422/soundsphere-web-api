local Community_leaderboards = require("models.community_leaderboards")

return function(self)
	if self.context.community_leaderboard then return true end
	local community_id = self.params.community_id
	local leaderboard_id = self.params.leaderboard_id
	if community_id and user_id then
		self.context.community_leaderboard = Community_leaderboards:find({
			community_id = community_id,
			leaderboard_id = leaderboard_id,
		})
	end
	return self.context.community_leaderboard
end
