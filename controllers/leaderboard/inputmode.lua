local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")

local leaderboard_inputmodes_c = {}

leaderboard_inputmodes_c.PUT = function(params)
    local leaderboard_inputmode = {
        leaderboard_id = params.leaderboard_id,
        inputmode_id = params.inputmode_id,
    }
    if not Leaderboard_inputmodes:find(leaderboard_inputmode) then
        Leaderboard_inputmodes:create(leaderboard_inputmode)
    end

	return 200, {}
end

leaderboard_inputmodes_c.DELETE = function(params)
    local leaderboard_inputmode = Leaderboard_inputmodes:find({
        leaderboard_id = params.leaderboard_id,
        inputmode_id = params.inputmode_id,
    })
    if leaderboard_inputmode then
        leaderboard_inputmode:delete()
    end

	return 200, {}
end

return leaderboard_inputmodes_c
