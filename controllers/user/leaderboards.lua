local Leaderboard_users = require("models.leaderboard_users")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local user_leaderboards_c = Controller:new()

user_leaderboards_c.path = "/users/:user_id[%d]/leaderboards"
user_leaderboards_c.methods = {"GET"}

user_leaderboards_c.policies.GET = {{"permit"}}
user_leaderboards_c.GET = function(request)
	local params = request.params
    local leaderboard_users = Leaderboard_users:find_all({params.user_id}, "user_id")
	preload(leaderboard_users, "leaderboard")

    local leaderboards = {}
	for _, leaderboard_user in ipairs(leaderboard_users) do
        table.insert(leaderboards, leaderboard_user.leaderboard)
	end

	local count = Leaderboard_users:count()

	return {json = {
		total = count,
		filtered = count,
		leaderboards = leaderboards
	}}
end

return user_leaderboards_c
