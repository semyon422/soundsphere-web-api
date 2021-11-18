local Model = require("lapis.db.model").Model
local toboolean = require("toboolean")

local Community_users = Model:extend(
	"community_users",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"user", belongs_to = "users", key = "user_id"},
		}
	}
)

local _load = Community_users.load
function Community_users:load(row)
	row.accepted = toboolean(row.accepted)
	row.invitation = toboolean(row.invitation)
	return _load(self, row)
end

return Community_users
