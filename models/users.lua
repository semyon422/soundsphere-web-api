local Model = require("lapis.db.model").Model
local hide_fields = require("util.hide_fields")
local toboolean = require("util.toboolean")

local Users = Model:extend(
	"users",
	{
		relations = {
			{"user_roles", has_many = "user_roles", key = "user_id"},
			{"user_inputmodes", has_many = "user_inputmodes", key = "user_id"},
			{"community_users", has_many = "community_users", key = "user_id"},
			{"user_relations", has_many = "user_relations", key = "user_id"},
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
	row.is_banned = toboolean(row.is_banned)
	row.latest_activity = tonumber(row.latest_activity)
	row.latest_score_submitted_at = tonumber(row.latest_score_submitted_at)
	row.created_at = tonumber(row.created_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Users
