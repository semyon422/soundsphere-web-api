local Leaderboard_users = require("models.leaderboard_users")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("leaderboard_user", function(self)
	local leaderboard_id = self.params.leaderboard_id
	local user_id = self.params.user_id
	if leaderboard_id and user_id then
		return Leaderboard_users:find({
			leaderboard_id = leaderboard_id,
			user_id = user_id,
		})
	end
end)
