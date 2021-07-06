local Model = require("lapis.db.model").Model

local Leaderboard_tables = Model:extend(
	"leaderboard_tables",
	{
		relations = {
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
			{"table", belongs_to = "tables", key = "table_id"},
		}
	}
)

return Leaderboard_tables
