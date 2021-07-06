local Leaderboard_users = require("models.leaderboard_users")
local preload = require("lapis.db.model").preload

local leaderboard_users_c = {}

leaderboard_users_c.GET = function(params)
    local leaderboard_users = Leaderboard_users:find_all({params.leaderboard_id}, "leaderboard_id")
	preload(leaderboard_users, "leaderboard", "user")

	local count = Leaderboard_users:count()

	return 200, {
		total = count,
		filtered = count,
		users = leaderboard_users
	}
end

return leaderboard_users_c
