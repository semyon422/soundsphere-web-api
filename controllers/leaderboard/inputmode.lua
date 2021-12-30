local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")

local leaderboard_inputmode_c = Controller:new()

leaderboard_inputmode_c.path = "/leaderboards/:leaderboard_id[%d]/inputmodes/:inputmode"
leaderboard_inputmode_c.methods = {"PUT", "DELETE"}
leaderboard_inputmode_c.validations.path = {
	{"inputmode", type = "string", one_of = Inputmodes.list, param_type = "path"},
}

leaderboard_inputmode_c.context.PUT = {"leaderboard_inputmode", "request_session"}
leaderboard_inputmode_c.policies.PUT = {{"authenticated"}}
leaderboard_inputmode_c.PUT = function(self)
	local params = self.params

    local leaderboard_inputmode = self.context.leaderboard_inputmode
    if not leaderboard_inputmode then
        leaderboard_inputmode = Leaderboard_inputmodes:create({
			leaderboard_id = params.leaderboard_id,
			inputmode = Inputmodes:for_db(params.inputmode),
		})
    end

	return {json = {leaderboard_inputmode = leaderboard_inputmode}}
end

leaderboard_inputmode_c.context.DELETE = {"leaderboard_inputmode", "request_session"}
leaderboard_inputmode_c.policies.DELETE = {{"authenticated"}}
leaderboard_inputmode_c.DELETE = function(self)
    local leaderboard_inputmode = self.context.leaderboard_inputmode
    leaderboard_inputmode:delete()

	return {status = 204}
end

return leaderboard_inputmode_c
