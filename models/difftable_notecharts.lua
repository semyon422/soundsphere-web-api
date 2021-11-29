local Model = require("lapis.db.model").Model

local Difftable_notecharts = Model:extend(
	"difftable_notecharts",
	{
		relations = {
			{"difftable", belongs_to = "difftables", key = "difftable_id"},
			{"notechart", belongs_to = "notecharts", key = "notechart_id"},
		}
	}
)

return Difftable_notecharts
