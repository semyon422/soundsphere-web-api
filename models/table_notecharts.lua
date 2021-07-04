local Model = require("lapis.db.model").Model

local table_notecharts = Model:extend(
	"table_notecharts",
	{
		relations = {
			{"table", belongs_to = "tables", key = "table_id"},
			{"notechart", belongs_to = "notecharts", key = "notechart_id"},
		}
	}
)

return table_notecharts
