local Model = require("lapis.db.model").Model

local Leaderboard_users = Model:extend(
	"leaderboard_users",
	{
		relations = {
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
			{"user", belongs_to = "users", key = "user_id"},
		}
	}
)

return Leaderboard_users
