local Model = require("lapis.db.model").Model

local Containers = Model:extend(
	"containers",
	{
		relations = {
			{"format", belongs_to = "formats", key = "format_id"}
		}
	}
)

return Containers
