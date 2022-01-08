local Model = require("lapis.db.model").Model
local Inputmodes = require("enums.inputmodes")

local Community_inputmodes = Model:extend(
	"community_inputmodes",
	{
		relations = {
			{"community", belongs_to = "communities", key = "community_id"},
		}
	}
)

local function to_name(self)
	self.inputmode = Inputmodes:to_name(self.inputmode)
	return self
end

local function for_db(self)
	self.inputmode = Inputmodes:for_db(self.inputmode)
	return self
end

function Community_inputmodes.to_name(self, row) return to_name(row) end
function Community_inputmodes.for_db(self, row) return for_db(row) end

local _load = Community_inputmodes.load
function Community_inputmodes:load(row)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Community_inputmodes
