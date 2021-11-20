local Model = require("lapis.db.model").Model
local toboolean = require("toboolean")

local Quick_logins = Model:extend(
	"quick_logins",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"}
		}
	}
)

local _load = Quick_logins.load
function Quick_logins:load(row)
	row.complete = toboolean(row.complete)
	return _load(self, row)
end

return Quick_logins
