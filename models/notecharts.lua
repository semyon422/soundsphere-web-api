local Model = require("lapis.db.model").Model

local notecharts = Model:extend(
	"notecharts",
	{
		relations = {
			{"container", belongs_to = "containers", key = "container_id"},
			{"input_mode", belongs_to = "input_modes", key = "input_mode_id"},
		}
	}
)

return notecharts
