local Model = require("lapis.db.model").Model
local Roles = require("enums.roles")

local User_roles = Model:extend(
	"user_roles",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
		},
		url_params = function(self, req, ...)
			return "user.role", {role = self.role, user_id = self.user_id}, ...
		end,
	}
)

local function to_name(self)
	self.role = Roles:to_name(self.role)
	return self
end

local function for_db(self)
	self.role = Roles:for_db(self.role)
	return self
end

function User_roles.to_name(self, row) return to_name(row) end
function User_roles.for_db(self, row) return for_db(row) end

local _load = User_roles.load
function User_roles:load(row)
	row.expires_at = tonumber(row.expires_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return User_roles
