local Model = require("lapis.db.model").Model

local community_users = Model:extend(
	"community_users",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
			{"user", belongs_to = "users", key = "user_id"},
		}
	}
)

return community_users
