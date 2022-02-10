local Leaderboard_difftables = require("models.leaderboard_difftables")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("leaderboard_difftable", function(self)
	local leaderboard_id = self.params.leaderboard_id
	local difftable_id = self.params.difftable_id
	if leaderboard_id and difftable_id then
		return Leaderboard_difftables:find({
			leaderboard_id = leaderboard_id,
			difftable_id = difftable_id,
		})
	end
end)
