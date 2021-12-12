local Model = require("lapis.db.model").Model

local Difftable = Model:extend(
	"difftables",
	{
		relations = {
			{"community_difftables", has_many = "community_difftables", key = "difftable_id"},
			{"difftable_inputmodes", has_many = "difftable_inputmodes", key = "difftable_id"},
			{"owner_community", belongs_to = "communities", key = "owner_community_id"},
		}
	}
)

return Difftable
