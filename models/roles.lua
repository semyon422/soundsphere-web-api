local Model = require("lapis.db.model").Model

local roles = Model:extend(
	"roles",
	{
		relations = {
			{"user_roles", has_many = "user_roles", key = "role_id"},
			{"group_roles", has_many = "group_roles", key = "role_id"},
		}
	}
)

return roles
