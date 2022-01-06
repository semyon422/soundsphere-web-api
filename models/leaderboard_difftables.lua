local Model = require("lapis.db.model").Model

local Leaderboard_difftables = Model:extend(
	"leaderboard_difftables",
	{
		relations = {
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
			{"difftable", belongs_to = "difftables", key = "difftable_id"},
		},
		url_params = function(self, req, ...)
			return "leaderboard.difftable", {leaderboard_id = self.leaderboard_id, difftable_id = self.difftable_id}, ...
		end,
	}
)

return Leaderboard_difftables
