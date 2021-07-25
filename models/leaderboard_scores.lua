local Model = require("lapis.db.model").Model

local Leaderboard_scores = Model:extend(
	"leaderboard_scores",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
			{"notechart", belongs_to = "notecharts", key = "notechart_id"},
			{"score", belongs_to = "scores", key = "score_id"},
		}
	}
)

return Leaderboard_scores
