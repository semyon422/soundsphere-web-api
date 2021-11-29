local Model = require("lapis.db.model").Model

local Community_difftables = Model:extend(
	"community_difftables",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"difftable", belongs_to = "difftables", key = "difftable_id"},
		}
	}
)

return Community_difftables
