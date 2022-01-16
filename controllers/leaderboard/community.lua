local Controller = require("Controller")

local leaderboard_community_c = Controller:new()

leaderboard_community_c.path = "/leaderboards/:leaderboard_id[%d]/communities/:community_id[%d]"
leaderboard_community_c.methods = {"GET"}

leaderboard_community_c.context.GET = {"community_leaderboard"}
leaderboard_community_c.policies.GET = {{"context_loaded"}}
leaderboard_community_c.GET = function(self)
	return {json = {community_leaderboard = self.context.community_leaderboard}}
end

return leaderboard_community_c
