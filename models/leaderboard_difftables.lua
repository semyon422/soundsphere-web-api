local Model = require("lapis.db.model").Model

local Leaderboard_difftables = Model:extend(
	"leaderboard_difftables",
	{
		relations = {
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
			{"difftable", belongs_to = "difftables", key = "difftable_id"},
		}
	}
)

return Leaderboard_difftables
