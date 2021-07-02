local leaderboard_tables = require("models.leaderboard_tables")
local util = require("lapis.util")

local leaderboard_tables_c = {}

leaderboard_tables_c.PUT = function(params)
    local entry = {
        leaderboard_id = params.leaderboard_id,
        table_id = params.table_id,
    }
    local leaderboard_table = leaderboard_tables:find(entry)
    if not leaderboard_table then
        leaderboard_tables:create(entry)
    end

	return 200, {leaderboard_table = entry}
end

leaderboard_tables_c.DELETE = function(params)
    local entry = {
        leaderboard_id = params.leaderboard_id,
        table_id = params.table_id,
    }
    local leaderboard_table = leaderboard_tables:find(entry)
    if leaderboard_table then
        leaderboard_table:delete()
    end

	return 200, {}
end

return leaderboard_tables_c
