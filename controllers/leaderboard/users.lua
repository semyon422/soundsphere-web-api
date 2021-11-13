local Leaderboard_users = require("models.leaderboard_users")
local preload = require("lapis.db.model").preload

local leaderboard_users_c = {}

leaderboard_users_c.path = "/leaderboards/:leaderboard_id/users"
leaderboard_users_c.methods = {"GET"}
leaderboard_users_c.context = {}
leaderboard_users_c.policies = {
	GET = require("policies.public"),
}

leaderboard_users_c.GET = function(request)
	local params = request.params
    local leaderboard_users = Leaderboard_users:find_all({params.leaderboard_id}, "leaderboard_id")
	preload(leaderboard_users, "user")

	local users = {}
	for _, leaderboard_user in ipairs(leaderboard_users) do
		local user = leaderboard_user.user
		table.insert(users, {
			id = user.id,
			name = user.name,
			tag = user.tag,
			latest_activity = user.latest_activity,
		})
	end

	local count = Leaderboard_users:count()

	return 200, {
		total = count,
		filtered = count,
		users = users
	}
end

return leaderboard_users_c
