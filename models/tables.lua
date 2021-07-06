local Model = require("lapis.db.model").Model

local Tables = Model:extend(
	"tables",
	{
		relations = {
			{"community_leaderboards", has_many = "community_leaderboards", key = "table_id"}
		}
	}
)

return Tables
