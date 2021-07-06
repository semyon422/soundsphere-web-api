local Leaderboard_tables = require("models.leaderboard_tables")

local leaderboard_tables_c = {}

leaderboard_tables_c.PUT = function(params)
    local leaderboard_table = {
        leaderboard_id = params.leaderboard_id,
        table_id = params.table_id,
    }
    leaderboard_table = Leaderboard_tables:find(leaderboard_table)
    if not leaderboard_table then
        Leaderboard_tables:create(leaderboard_table)
    end

	return 200, {leaderboard_table = leaderboard_table}
end

leaderboard_tables_c.DELETE = function(params)
    local leaderboard_table = {
        leaderboard_id = params.leaderboard_id,
        table_id = params.table_id,
    }
    leaderboard_table = Leaderboard_tables:find(leaderboard_table)
    if leaderboard_table then
        leaderboard_table:delete()
    end

	return 200, {}
end

return leaderboard_tables_c
