local Model = require("lapis.db.model").Model

local User_roles = Model:extend(
	"user_roles",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
		}
	}
)

local _load = User_roles.load
function User_roles:load(row)
	row.expires_at = tonumber(row.expires_at)
	return _load(self, row)
end

return User_roles
