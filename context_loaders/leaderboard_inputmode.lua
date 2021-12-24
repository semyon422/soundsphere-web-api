local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")

return function(self)
	if self.context.leaderboard_inputmode then return true end
	local leaderboard_id = self.params.leaderboard_id
	local inputmode = self.params.inputmode
	if leaderboard_id and inputmode then
		self.context.leaderboard_inputmode = Leaderboard_inputmodes:find({
			leaderboard_id = leaderboard_id,
			inputmode = Inputmodes:for_db(inputmode),
		})
	end
	return self.context.leaderboard_inputmode
end
