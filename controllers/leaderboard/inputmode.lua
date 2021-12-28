local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")

local leaderboard_inputmode_c = Controller:new()

leaderboard_inputmode_c.path = "/leaderboards/:leaderboard_id[%d]/inputmodes/:inputmode"
leaderboard_inputmode_c.methods = {"PUT", "DELETE"}

leaderboard_inputmode_c.context.PUT = {"leaderboard_inputmode", "request_session"}
leaderboard_inputmode_c.policies.PUT = {{"authenticated"}}
leaderboard_inputmode_c.PUT = function(request)
	local params = request.params

    local leaderboard_inputmode = request.context.leaderboard_inputmode
    if not leaderboard_inputmode then
        leaderboard_inputmode = leaderboard_inputmodeLeaderboard_inputmodes:create({
			leaderboard_id = params.leaderboard_id,
			inputmode = Inputmodes:for_db(params.inputmode),
		})
    end

	return 200, {leaderboard_inputmode = leaderboard_inputmode}
end

leaderboard_inputmode_c.context.DELETE = {"leaderboard_inputmode", "request_session"}
leaderboard_inputmode_c.policies.DELETE = {{"authenticated"}}
leaderboard_inputmode_c.DELETE = function(request)
    local leaderboard_inputmode = request.context.leaderboard_inputmode
    leaderboard_inputmode:delete()

	return 200, {leaderboard_inputmode = leaderboard_inputmode}
end

return leaderboard_inputmode_c
