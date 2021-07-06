local Model = require("lapis.db.model").Model

local Groups = Model:extend(
	"groups",
	{
		relations = {
			{"group_roles", has_many = "group_roles", key = "group_id"},
			{"group_users", has_many = "group_users", key = "group_id"},
		}
	}
)

return Groups
