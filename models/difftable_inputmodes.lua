local Model = require("lapis.db.model").Model

local Difftable_inputmodes = Model:extend(
	"difftable_inputmodes",
	{
		relations = {
			{"difftable", belongs_to = "difftables", key = "difftable_id"},
		}
	}
)

return Difftable_inputmodes
