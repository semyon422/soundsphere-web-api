local Model = require("lapis.db.model").Model

local Group_roles = Model:extend(
	"Group_roles",
	{
		relations = {
			{"group", belongs_to = "groups", key = "group_id"},
			{"domain", belongs_to = "domains", key = "domain_id"},
		}
	}
)

return Group_roles
