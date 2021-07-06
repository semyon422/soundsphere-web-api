local Model = require("lapis.db.model").Model

local Leaderboards = Model:extend(
	"leaderboards",
	{
		relations = {
			{"leaderboard_tables", has_many = "leaderboard_tables", key = "leaderboard_id"},
			{"community_leaderboards", has_many = "community_leaderboards", key = "leaderboard_id"},
		}
	}
)

return Leaderboards
