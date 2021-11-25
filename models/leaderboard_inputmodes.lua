local Model = require("lapis.db.model").Model
local Inputmodes = require("enums.inputmodes")

local Leaderboard_inputmodes = Model:extend(
	"leaderboard_inputmodes",
	{
		relations = {
			{"leaderboard", belongs_to = "communities", key = "leaderboard_id"},
		}
	}
)

Leaderboard_inputmodes.get_inputmodes = function(self, leaderboard_inputmodes)
	local inputmodes = {}
	for _, leaderboard_inputmode in ipairs(leaderboard_inputmodes) do
		table.insert(inputmodes, Inputmodes:to_name(leaderboard_inputmode.inputmode))
	end
	return inputmodes
end

return Leaderboard_inputmodes
