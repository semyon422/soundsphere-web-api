local Leaderboards = require("models.leaderboards")

local leaderboard_c = {}

leaderboard_c.GET = function(params)
	local leaderboard = Leaderboards:find(params.leaderboard_id)

	return 200, {leaderboard = leaderboard}
end

leaderboard_c.PATCH = function(params)
	local leaderboard = Leaderboards:find(params.leaderboard.id)

	leaderboard.name = params.leaderboard.name
	leaderboard.description = params.leaderboard.description

	leaderboard:update("name", "description")

	return 200, {leaderboard = leaderboard}
end

return leaderboard_c
