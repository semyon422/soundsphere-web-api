local Model = require("lapis.db.model").Model

local Community_tables = Model:extend(
	"community_tables",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"table", belongs_to = "tables", key = "table_id"},
		}
	}
)

return Community_tables