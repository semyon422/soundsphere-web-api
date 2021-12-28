local Leaderboard_users = require("models.leaderboard_users")
local Controller = require("Controller")

local leaderboard_user_c = Controller:new()

leaderboard_user_c.path = "/leaderboards/:leaderboard_id[%d]/users/:user_id[%d]"
leaderboard_user_c.methods = {"PUT", "DELETE"}

leaderboard_user_c.context.PUT = {"leaderboard_user", "request_session"}
leaderboard_user_c.policies.PUT = {{"authenticated"}}
leaderboard_user_c.PUT = function(request)
	local params = request.params
    local leaderboard_user = request.context.leaderboard_user
    if not leaderboard_user then
        leaderboard_user = Leaderboard_users:create({
			leaderboard_id = params.leaderboard_id,
			user_id = params.user_id,
		})
    end

	return 200, {leaderboard_user = leaderboard_user}
end

leaderboard_user_c.context.DELETE = {"leaderboard_user", "request_session"}
leaderboard_user_c.policies.DELETE = {{"authenticated", "context_loaded"}}
leaderboard_user_c.DELETE = function(request)
    local leaderboard_user = request.context.leaderboard_user
    leaderboard_user:delete()

	return 200, {leaderboard_user = leaderboard_user}
end

return leaderboard_user_c
