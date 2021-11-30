local Model = require("lapis.db.model").Model

local Leaderboard_inputmodes = Model:extend(
	"leaderboard_inputmodes",
	{
		relations = {
			{"leaderboard", belongs_to = "communities", key = "leaderboard_id"},
		}
	}
)

return Leaderboard_inputmodes
