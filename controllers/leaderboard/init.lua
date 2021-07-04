local leaderboards = require("models.leaderboards")

local leaderboard_c = {}

leaderboard_c.GET = function(params)
	local db_leaderboard_entry = leaderboards:find(params.leaderboard_id)

	return 200, {leaderboard = db_leaderboard_entry}
end

leaderboard_c.PATCH = function(params)
	local leaderboard_entry = leaderboards:find(params.leaderboard.id)

	leaderboard_entry.name = params.leaderboard.name
	leaderboard_entry.description = params.leaderboard.description

	leaderboard_entry:update("name", "description")

	return 200, {leaderboard = leaderboard_entry}
end

return leaderboard_c
