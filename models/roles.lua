local model = require("lapis.db.model")
local Model, enum = model.Model, model.enum

local roles = Model:extend(
	"roles",
	{
		relations = {
			{"user_roles", has_many = "user_roles", key = "role_id"},
			{"group_roles", has_many = "group_roles", key = "role_id"},
		}
	}
)

roles.types = enum({
	creator = 1,
	admin = 2,
})

return roles
