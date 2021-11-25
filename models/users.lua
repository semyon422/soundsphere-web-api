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

Users.safe_copy = function(self, user)
	if not user then return end
	local safe_user = {}
	safe_user.id = user.id
	safe_user.name = user.name
	safe_user.tag = user.tag
	safe_user.latest_activity = user.latest_activity
	safe_user.creation_time = user.creation_time
	safe_user.description = user.description
	return safe_user
end

return Users
