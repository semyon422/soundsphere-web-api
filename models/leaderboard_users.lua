local Model = require("lapis.db.model").Model

local leaderboard_users = Model:extend(
	"leaderboard_users",
	{
		relations = {
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
			{"user", belongs_to = "users", key = "user_id"},
		}
	}
)

return leaderboard_users
