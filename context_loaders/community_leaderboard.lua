local Community_leaderboards = require("models.community_leaderboards")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("community_leaderboard", function(self)
	local community_id = self.params.community_id
	local leaderboard_id = self.params.leaderboard_id
	if community_id and leaderboard_id then
		return Community_leaderboards:find({
			community_id = community_id,
			leaderboard_id = leaderboard_id,
		})
	end
end)
