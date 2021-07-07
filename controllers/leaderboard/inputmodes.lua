local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local preload = require("lapis.db.model").preload

local inputmodes_c = {}

inputmodes_c.GET = function(params)
	local leaderboard_inputmodes = Leaderboard_inputmodes:find_all({params.leaderboard_id}, "leaderboard_id")
	preload(leaderboard_inputmodes, "inputmode")

	local inputmodes = {}
	for _, leaderboard_inputmode in ipairs(leaderboard_inputmodes) do
		table.insert(inputmodes, leaderboard_inputmode.inputmode)
	end

	local count = Leaderboard_inputmodes:count()

	return 200, {
		total = count,
		filtered = count,
		inputmodes = inputmodes
	}
end

return inputmodes_c
