local Model = require("lapis.db.model").Model
local Inputmodes = require("enums.inputmodes")

local Leaderboard_inputmodes = Model:extend(
	"leaderboard_inputmodes",
	{
		relations = {
			{"leaderboard", belongs_to = "leaderboards", key = "leaderboard_id"},
		},
		url_params = function(self, req, ...)
			return "leaderboard.inputmode", {inputmode = self.inputmode, leaderboard_id = self.leaderboard_id}, ...
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

function Leaderboard_inputmodes.to_name(self, row) return to_name(row) end
function Leaderboard_inputmodes.for_db(self, row) return for_db(row) end

local _load = Leaderboard_inputmodes.load
function Leaderboard_inputmodes:load(row)
	row.to_name = to_name
	row.for_db = for_db
	return _load(self, row)
end

return Leaderboard_inputmodes
