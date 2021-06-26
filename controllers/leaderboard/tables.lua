local leaderboard_tables = require("models.leaderboard_tables")
local util = require("lapis.util")
local preload = require("lapis.db.model").preload

local leaderboard_tables_c = {}

leaderboard_tables_c.GET = function(req, res, go)
    local sub_leaderboard_tables = leaderboard_tables:find_all({req.params.leaderboard_id}, "leaderboard_id")
	preload(sub_leaderboard_tables, "leaderboard", "table")

	res.body = util.to_json({tables = sub_leaderboard_tables})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return leaderboard_tables_c
