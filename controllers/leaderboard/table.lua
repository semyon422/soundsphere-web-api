local leaderboard_tables = require("models.leaderboard_tables")
local util = require("lapis.util")

local leaderboard_tables_c = {}

leaderboard_tables_c.PUT = function(req, res, go)
    local entry = {
        leaderboard_id = req.params.leaderboard_id,
        table_id = req.params.table_id,
    }
    local leaderboard_table = leaderboard_tables:find(entry)
    if not leaderboard_table then
        leaderboard_tables:create(entry)
    end

	res.body = util.to_json({leaderboard_table = entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

leaderboard_tables_c.DELETE = function(req, res, go)
    local entry = {
        leaderboard_id = req.params.leaderboard_id,
        table_id = req.params.table_id,
    }
    local leaderboard_table = leaderboard_tables:find(entry)
    if leaderboard_table then
        leaderboard_table:delete()
    end

	res.body = util.to_json({})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return leaderboard_tables_c
