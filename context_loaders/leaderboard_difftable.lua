local Leaderboard_difftables = require("models.leaderboard_difftables")

return function(self)
	if self.context.leaderboard_difftable then return true end
	local leaderboard_id = self.params.leaderboard_id
	local difftable_id = self.params.difftable_id
	if leaderboard_id and difftable_id then
		self.context.leaderboard_difftable = Leaderboard_difftables:find({
			leaderboard_id = leaderboard_id,
			difftable_id = difftable_id,
		})
	end
	return self.context.leaderboard_difftable
end
