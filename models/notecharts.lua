local Model = require("lapis.db.model").Model

local Notecharts = Model:extend(
	"notecharts",
	{
		relations = {
			{"container", belongs_to = "containers", key = "container_id"},
		}
	}
)

return Notecharts
