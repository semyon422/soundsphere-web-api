local Leaderboard_users = require("models.leaderboard_users")

local leaderboard_users_c = {}

leaderboard_users_c.PUT = function(params)
    local leaderboard_user = {
        leaderboard_id = params.leaderboard_id,
        user_id = params.user_id,
    }
    if not Leaderboard_users:find(leaderboard_user) then
        Leaderboard_users:create(leaderboard_user)
    end

	return 200, {}
end

leaderboard_users_c.DELETE = function(params)
    local leaderboard_user = Leaderboard_users:find({
        leaderboard_id = params.leaderboard_id,
        user_id = params.user_id,
    })
    if leaderboard_user then
        leaderboard_user:delete()
    end

	return 200, {}
end

return leaderboard_users_c
