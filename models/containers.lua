local Model = require("lapis.db.model").Model

local containers = Model:extend(
	"containers",
	{
		relations = {
			{"format", belongs_to = "formats", key = "format_id"}
		}
	}
)

return containers
