local leaderboard_users = require("models.leaderboard_users")
local preload = require("lapis.db.model").preload

local leaderboard_users_c = {}

leaderboard_users_c.GET = function(params)
    local sub_leaderboard_users = leaderboard_users:find_all({params.leaderboard_id}, "leaderboard_id")
	preload(sub_leaderboard_users, "leaderboard", "user")

	return 200, {users = sub_leaderboard_users}
end

return leaderboard_users_c
