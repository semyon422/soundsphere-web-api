local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")

local leaderboard_inputmode_c = {}

leaderboard_inputmode_c.path = "/leaderboards/:leaderboard_id/inputmodes/:inputmode"
leaderboard_inputmode_c.methods = {"PUT", "DELETE"}
leaderboard_inputmode_c.context = {"leaderboard"}
leaderboard_inputmode_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
}

leaderboard_inputmode_c.PUT = function(request)
	local params = request.params
    local leaderboard_inputmode = {
        leaderboard_id = params.leaderboard_id,
        inputmode = Inputmodes:for_db(params.inputmode),
    }
    if not Leaderboard_inputmodes:find(leaderboard_inputmode) then
        Leaderboard_inputmodes:create(leaderboard_inputmode)
    end

	return 200, {}
end

leaderboard_inputmode_c.DELETE = function(request)
	local params = request.params
    local leaderboard_inputmode = Leaderboard_inputmodes:find({
        leaderboard_id = params.leaderboard_id,
        inputmode = Inputmodes:for_db(params.inputmode),
    })
    if leaderboard_inputmode then
        leaderboard_inputmode:delete()
    end

	return 200, {}
end

return leaderboard_inputmode_c
