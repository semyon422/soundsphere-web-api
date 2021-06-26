local leaderboards = require("models.leaderboards")
local util = require("lapis.util")

local leaderboard_c = {}

leaderboard_c.GET = function(req, res, go)
	local db_leaderboard_entry = leaderboards:find(req.params.leaderboard_id)

	res.body = util.to_json({leaderboard = db_leaderboard_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return leaderboard_c
