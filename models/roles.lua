local model = require("lapis.db.model")
local Model, enum = model.Model, model.enum

local Roles = Model:extend(
	"roles",
	{
		relations = {
			{"user_roles", has_many = "user_roles", key = "role_id"},
			{"group_roles", has_many = "group_roles", key = "role_id"},
		}
	}
)

Roles.types = enum({
	creator = 1,
	admin = 2,
})

return Roles
