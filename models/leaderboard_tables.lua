local Model = require("lapis.db.model").Model

local leaderboard_tables = Model:extend(
	"leaderboard_tables",
	{
		relations = {
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"}
		}
	}
)

return leaderboard_tables
