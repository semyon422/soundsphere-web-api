local Model = require("lapis.db.model").Model
local Roles = require("models.roles")

local Users = Model:extend(
	"users",
	{
		relations = {
			{"roles", has_many = "roles", key = "subject_id", where = {subject_type = Roles.subject_types.users}}
		}
	}
)

return Users
