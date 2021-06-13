local Model = require("lapis.db.model").Model

local group_users = Model:extend(
	"group_users",
	{
		relations = {
			{"group", belongs_to = "groups", key = "group_id"},
			{"user", belongs_to = "users", key = "user_id"},
		}
	}
)

return group_users
