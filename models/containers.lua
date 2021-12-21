local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

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
	row.creation_time = tonumber(row.creation_time)
	return _load(self, row)
end

return Containers
