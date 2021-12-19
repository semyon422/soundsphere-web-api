local community_leaderboard_c = require("controllers.community.leaderboard")
local Controller = require("Controller")

local leaderboard_community_c = Controller:new()

community_leaderboard_c.path = "/communities/:community_id[%d]/leaderboards/:leaderboard_id[%d]"
leaderboard_community_c.methods = community_leaderboard_c.methods
leaderboard_community_c.context = community_leaderboard_c.context
leaderboard_community_c.policies = community_leaderboard_c.policies

leaderboard_community_c.PUT = community_leaderboard_c.PUT
leaderboard_community_c.DELETE = community_leaderboard_c.DELETE

return leaderboard_community_c
