local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("leaderboard_inputmode", function(self)
	local leaderboard_id = self.params.leaderboard_id
	local inputmode = self.params.inputmode
	if leaderboard_id and inputmode then
		return Leaderboard_inputmodes:find({
			leaderboard_id = leaderboard_id,
			inputmode = Inputmodes:for_db(inputmode),
		})
	end
end)
