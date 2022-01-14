local Model = require("lapis.db.model").Model
local Inputmodes = require("enums.inputmodes")

local Difftable_inputmodes = Model:extend(
	"difftable_inputmodes",
	{
		relations = {
			{"difftable", belongs_to = "difftables", key = "difftable_id"},
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

function Difftable_inputmodes.to_name(self, row) return to_name(row) end
function Difftable_inputmodes.for_db(self, row) return for_db(row) end

local _load = Difftable_inputmodes.load
function Difftable_inputmodes:load(row)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Difftable_inputmodes
