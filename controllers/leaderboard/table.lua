local Leaderboard_tables = require("models.leaderboard_tables")

local leaderboard_table_c = {}

leaderboard_table_c.PUT = function(params)
    local leaderboard_table = {
        leaderboard_id = params.leaderboard_id,
        table_id = params.table_id,
    }
    if not Leaderboard_tables:find(leaderboard_table) then
        Leaderboard_tables:create(leaderboard_table)
    end

	return 200, {}
end

leaderboard_table_c.DELETE = function(params)
    local leaderboard_table = Leaderboard_tables:find({
        leaderboard_id = params.leaderboard_id,
        table_id = params.table_id,
    })
    if leaderboard_table then
        leaderboard_table:delete()
    end

	return 200, {}
end

return leaderboard_table_c
