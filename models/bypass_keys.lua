local Model = require("lapis.db.model").Model
local Filehash = require("util.filehash")
local Bypass_actions = require("enums.bypass_actions")

local Bypass_keys = Model:extend(
	"bypass_keys",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
			{"target_user", belongs_to = "users", key = "target_user_id"},
		},
		url_params = function(self, req, ...)
			return "auth.key", {key_id = self.id}, ...
		end,
	}
)

local function to_name(self)
	self.key = Filehash:to_name(self.key)
	return self
end

local function for_db(self)
	self.key = Filehash:for_db(self.key)
	return self
end

function Bypass_keys.to_name(self, row) return to_name(row) end
function Bypass_keys.for_db(self, row) return for_db(row) end

local _load = Bypass_keys.load
function Bypass_keys:load(row)
	row.action = Bypass_actions:to_name(row.action)
	row.created_at = tonumber(row.created_at)
	row.expires_at = tonumber(row.expires_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Bypass_keys
