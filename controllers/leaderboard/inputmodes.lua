local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")

local inputmodes_c = {}

inputmodes_c.GET = function(params)
	local leaderboard_inputmodes = Leaderboard_inputmodes:find_all({params.leaderboard_id}, "leaderboard_id")

	local inputmodes = {}
	for _, leaderboard_inputmode in ipairs(leaderboard_inputmodes) do
		table.insert(inputmodes, Inputmodes:to_name(leaderboard_inputmode.inputmode))
	end

	local count = Leaderboard_inputmodes:count()

	return 200, {
		total = count,
		filtered = count,
		inputmodes = inputmodes
	}
end

return inputmodes_c
