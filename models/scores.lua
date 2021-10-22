local Model = require("lapis.db.model").Model

local Scores = Model:extend(
	"scores",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
			{"notechart", belongs_to = "notecharts", key = "notechart_id"},
			{"modifier", belongs_to = "modifiers", key = "modifier_id"},
			{"inputmode", belongs_to = "inputmodes", key = "inputmode_id"},
		}
	}
)

return Scores
