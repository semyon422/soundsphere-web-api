local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")

local leaderboard_inputmodes_c = {}

leaderboard_inputmodes_c.path = "/leaderboards/:leaderboard_id/inputmodes"
leaderboard_inputmodes_c.methods = {"GET"}
leaderboard_inputmodes_c.context = {}
leaderboard_inputmodes_c.policies = {
	GET = require("policies.public"),
}

leaderboard_inputmodes_c.GET = function(request)
	local params = request.params
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

return leaderboard_inputmodes_c
