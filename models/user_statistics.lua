local Model = require("lapis.db.model").Model

local user_statistics = Model:extend(
	"user_statistics",
	{
		relations = {
			{"user", belongs_to = "user", key = "user_id"},
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
		}
	}
)

return user_statistics
