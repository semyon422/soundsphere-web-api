local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")

local Sessions = Model:extend(
	"sessions",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
		}
	}
)

local _load = Sessions.load
function Sessions:load(row)
	row.active = toboolean(row.active)
	row.created_at = tonumber(row.created_at)
	row.updated_at = tonumber(row.updated_at)
	return _load(self, row)
end

return Sessions
