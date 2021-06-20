local Model = require("lapis.db.model").Model

local scoers = Model:extend(
	"scoers",
	{
		relations = {
			{"user", belongs_to = "user", key = "user_id"},
			{"notechart", belongs_to = "notecharts", key = "notechart_id"},
			{"modifier", belongs_to = "modifiers", key = "modifier_id"},
			{"input_mode", belongs_to = "input_modes", key = "input_mode_id"},
		}
	}
)

return scoers
