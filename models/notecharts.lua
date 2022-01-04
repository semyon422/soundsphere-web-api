local Model = require("lapis.db.model").Model
local toboolean = require("util.toboolean")
local Inputmodes = require("enums.inputmodes")

local Notecharts = Model:extend(
	"notecharts",
	{
		relations = {
			{"file", belongs_to = "files", key = "file_id"},
		},
		url_params = function(self, req, ...)
			return "notechart", {notechart_id = self.id}, ...
		end,
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

function Notecharts.to_name(self, row) return to_name(row) end
function Notecharts.for_db(self, row) return for_db(row) end

local _load = Notecharts.load
function Notecharts:load(row)
	row.is_valid = toboolean(row.is_valid)
	row.created_at = tonumber(row.created_at)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Notecharts
