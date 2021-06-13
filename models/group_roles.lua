local Model = require("lapis.db.model").Model

local group_roles = Model:extend(
	"group_roles",
	{
		relations = {
			{"group", belongs_to = "groups", key = "group_id"},
			{"role", belongs_to = "roles", key = "role_id"},
			{"domain", belongs_to = "domains", key = "domain_id"},
		}
	}
)

return group_roles
