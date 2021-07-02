local leaderboards = require("models.leaderboards")
local util = require("lapis.util")

local leaderboard_c = {}

leaderboard_c.GET = function(params)
	local db_leaderboard_entry = leaderboards:find(params.leaderboard_id)

	return 200, {leaderboard = db_leaderboard_entry}
end

return leaderboard_c
