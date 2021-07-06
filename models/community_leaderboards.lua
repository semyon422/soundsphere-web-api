local Model = require("lapis.db.model").Model

local Community_leaderboards = Model:extend(
	"community_leaderboards",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
		}
	}
)

return Community_leaderboards
