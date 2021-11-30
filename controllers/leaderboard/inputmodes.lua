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
	local inputmodes = Inputmodes:entries_to_list(leaderboard_inputmodes)

	return 200, {
		total = #inputmodes,
		filtered = #inputmodes,
		inputmodes = inputmodes
	}
end

return leaderboard_inputmodes_c
