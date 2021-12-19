local Leaderboard_users = require("models.leaderboard_users")
local Controller = require("Controller")

local leaderboard_user_c = Controller:new()

leaderboard_user_c.path = "/leaderboards/:leaderboard_id/users/:user_id"
leaderboard_user_c.methods = {"PUT", "DELETE"}
leaderboard_user_c.context = {}
leaderboard_user_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
}

leaderboard_user_c.PUT = function(request)
	local params = request.params
    local leaderboard_user = {
        leaderboard_id = params.leaderboard_id,
        user_id = params.user_id,
    }
    if not Leaderboard_users:find(leaderboard_user) then
        Leaderboard_users:create(leaderboard_user)
    end

	return 200, {}
end

leaderboard_user_c.DELETE = function(request)
	local params = request.params
    local leaderboard_user = Leaderboard_users:find({
        leaderboard_id = params.leaderboard_id,
        user_id = params.user_id,
    })
    if leaderboard_user then
        leaderboard_user:delete()
    end

	return 200, {}
end

return leaderboard_user_c
