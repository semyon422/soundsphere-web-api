local Model = require("lapis.db.model").Model

local notecharts = Model:extend(
	"notecharts",
	{
		relations = {
			{"container", belongs_to = "containers", key = "container_id"},
			{"inputmode", belongs_to = "inputmodes", key = "inputmode_id"},
		}
	}
)

return notecharts
