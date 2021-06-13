local Model = require("lapis.db.model").Model

local community_leaderboards = Model:extend(
	"community_leaderboards",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
		}
	}
)

return community_leaderboards
