local Model = require("lapis.db.model").Model
local Roles = require("models.roles")

local Group_users = Model:extend(
	"group_users",
	{
		relations = {
			{"group", belongs_to = "groups", key = "group_id"},
			{"user", belongs_to = "users", key = "user_id"},
			{"group_roles", has_many = "roles", key = "subject_id", where = {subject_type = Roles.subject_types.groups}},
		}
	}
)

return Group_users
