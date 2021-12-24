local Leaderboards = require("models.leaderboards")

return function(self)
	if self.context.leaderboard then return true end
	local leaderboard_id = self.params.leaderboard_id
	if leaderboard_id then
		self.context.leaderboard = Leaderboards:find(leaderboard_id)
	end
	return self.context.leaderboard
end
