local Leaderboards = require("models.leaderboards")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("leaderboard", function(self)
	local leaderboard_id = self.params.leaderboard_id
	if leaderboard_id then
		return Leaderboards:find(leaderboard_id)
	end
end)
