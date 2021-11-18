local Model = require("lapis.db.model").Model
local toboolean = require("toboolean")

local Containers = Model:extend(
	"containers",
	{
		relations = {
			{"format", belongs_to = "formats", key = "format_id"}
		}
	}
)

local _load = Containers.load
function Containers:load(row)
	row.uploaded = toboolean(row.uploaded)
	row.imported = toboolean(row.imported)
	return _load(self, row)
end

return Containers
