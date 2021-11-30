local Model = require("lapis.db.model").Model

local Community_inputmodes = Model:extend(
	"community_inputmodes",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
		}
	}
)

return Community_inputmodes
