local Model = require("lapis.db.model").Model
local Ip = require("util.ip")

local User_locations = Model:extend(
	"user_locations",
	{
		relations = {
			{"user", belongs_to = "users", key = "user_id"},
		},
	}
)

local function to_name(self)
	self.ip = Ip:to_name(self.ip)
	return self
end

local function for_db(self)
	self.ip = Ip:for_db(self.ip)
	return self
end

function User_locations.to_name(self, row) return to_name(row) end
function User_locations.for_db(self, row) return for_db(row) end

local _load = User_locations.load
function User_locations:load(row)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return User_locations
