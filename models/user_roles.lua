local Model = require("lapis.db.model").Model

local User_roles = Model:extend(
	"user_roles",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
		}
	}
)

return User_roles
