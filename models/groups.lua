local Model = require("lapis.db.model").Model
local Roles = require("models.roles")

local Groups = Model:extend(
	"groups",
	{
		relations = {
			{"roles", has_many = "roles", key = "subject_id", where = {subject_type = Roles.subject_types.groups}},
			{"group_users", has_many = "group_users", key = "group_id"},
		}
	}
)

return Groups
