local Model = require("lapis.db.model").Model

local User_roles = Model:extend(
	"user_roles",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
			{"role", belongs_to = "roles", key = "role_id"},
			{"domain", belongs_to = "domains", key = "domain_id"},
		}
	}
)

return User_roles
