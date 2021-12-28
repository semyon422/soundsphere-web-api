local Leaderboard_users = require("models.leaderboard_users")
local Users = require("models.users")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local leaderboard_users_c = Controller:new()

leaderboard_users_c.path = "/leaderboards/:leaderboard_id[%d]/users"
leaderboard_users_c.methods = {"GET"}

leaderboard_users_c.policies.GET = {{"permit"}}
leaderboard_users_c.validations.GET = {
	require("validations.no_data"),
}
leaderboard_users_c.GET = function(request)
	local params = request.params
    local leaderboard_users = Leaderboard_users:find_all({params.leaderboard_id}, "leaderboard_id")

	if params.no_data then
		return 200, {
			total = #leaderboard_users,
			filtered = #leaderboard_users,
		}
	end

	preload(leaderboard_users, "user")

	local users = {}
	for _, leaderboard_user in ipairs(leaderboard_users) do
		table.insert(users, leaderboard_user.user:to_name())
	end

	return 200, {
		total = #users,
		filtered = #users,
		users = users
	}
end

return leaderboard_users_c
