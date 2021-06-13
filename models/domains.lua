local Model = require("lapis.db.model").Model

local domains = Model:extend(
	"domains",
	{
		relations = {
			{"user_roles", has_many = "user_roles", key = "domain_id"},
			{"group_roles", has_many = "group_roles", key = "domain_id"},
		}
	}
)

return domains
