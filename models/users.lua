local Model = require("lapis.db.model").Model
local hide_fields = require("util.hide_fields")

local Users = Model:extend(
	"users",
	{
		relations = {
			{"roles", has_many = "user_roles", key = "user_id"},
			{"community_users", has_many = "community_users", key = "user_id", deny_auto = true},
		},
		url_params = function(self, req, ...)
			return "user", {user_id = self.id}, ...
		end,
	}
)

local not_safe_fields = {
	"email",
	"password",
}

local function to_name(self)
	return hide_fields(self, not_safe_fields)
end

local function for_db(self)
	return self
end

function Users.to_name(self, row) return to_name(row) end
function Users.for_db(self, row) return for_db(row) end

local _load = Users.load
function Users:load(row)
	row.latest_activity = tonumber(row.latest_activity)
	row.created_at = tonumber(row.created_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Users
