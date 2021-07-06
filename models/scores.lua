local Model = require("lapis.db.model").Model

local scoers = Model:extend(
	"scoers",
	{
		relations = {
			{"user", belongs_to = "user", key = "user_id"},
			{"notechart", belongs_to = "notecharts", key = "notechart_id"},
			{"modifier", belongs_to = "modifiers", key = "modifier_id"},
			{"inputmode", belongs_to = "inputmodes", key = "inputmode_id"},
		}
	}
)

return scoers
