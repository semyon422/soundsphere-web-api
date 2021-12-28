local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")
local hide_fields = require("util.hide_fields")
local Ip = require("util.ip")

local Sessions = Model:extend(
	"sessions",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
		},
		url_params = function(self, req, ...)
			return "user.session", {session_id = self.id, user_id = req.params.user_id}, ...
		end,
	}
)

local not_safe_fields = {
	-- ip = true,
}

local function to_name(self)
	self.ip = Ip:to_name(self.ip)
	return hide_fields(self, not_safe_fields)
end

local function for_db(self)
	return self
end

function Sessions.to_name(self, row) return to_name(row) end
function Sessions.for_db(self, row) return for_db(row) end

local _load = Sessions.load
function Sessions:load(row)
	row.active = toboolean(row.active)
	row.created_at = tonumber(row.created_at)
	row.updated_at = tonumber(row.updated_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Sessions
