local Model = require("lapis.db.model").Model

local Users = Model:extend(
	"users",
	{
		relations = {
			{"roles", has_many = "user_roles", key = "user_id"},
			{"community_users", has_many = "community_users", key = "user_id"},
		}
	}
)

local _load = Users.load
function Users:load(row)
	row.latest_activity = tonumber(row.latest_activity)
	row.creation_time = tonumber(row.creation_time)
	return _load(self, row)
end

local not_safe_fields = {
	email = true,
	password = true,
}

Users.safe_copy = function(self, user)
	if not user then return end
	local safe_user = {}
	for k, v in pairs(user) do
		if type(k) == "string" and not not_safe_fields[k] then
			safe_user[k] = v
		end
	end
	return safe_user
end

return Users
