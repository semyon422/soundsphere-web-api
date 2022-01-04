local Model = require("lapis.db.model").Model

local Leaderboards = Model:extend(
	"leaderboards",
	{
		relations = {
			{"leaderboard_difftables", has_many = "leaderboard_difftables", key = "leaderboard_id"},
			{"leaderboard_inputmodes", has_many = "leaderboard_inputmodes", key = "leaderboard_id"},
			{"leaderboard_requirements", has_many = "leaderboard_requirements", key = "leaderboard_id"},
			{"community_leaderboards", has_many = "community_leaderboards", key = "leaderboard_id"},
			{"top_user", belongs_to = "users", key = "top_user_id"},
		},
		url_params = function(self, req, ...)
			return "leaderboard", {leaderboard_id = self.id}, ...
		end,
	}
)

return Leaderboards
