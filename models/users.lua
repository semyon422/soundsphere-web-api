local Model = require("lapis.db.model").Model

local users = Model:extend(
	"users",
	{
		relations = {
			{"user_roles", has_many = "user_roles", key = "user_id"}
		}
	}
)

return users
