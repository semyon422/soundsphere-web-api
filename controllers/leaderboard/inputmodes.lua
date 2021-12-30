local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")

local leaderboard_inputmodes_c = Controller:new()

leaderboard_inputmodes_c.path = "/leaderboards/:leaderboard_id[%d]/inputmodes"
leaderboard_inputmodes_c.methods = {"GET"}

leaderboard_inputmodes_c.policies.GET = {{"permit"}}
leaderboard_inputmodes_c.validations.GET = {
	require("validations.no_data"),
}
leaderboard_inputmodes_c.GET = function(self)
	local params = self.params
	local leaderboard_inputmodes = Leaderboard_inputmodes:find_all({params.leaderboard_id}, "leaderboard_id")

	if params.no_data then
		return {json = {
			total = #leaderboard_inputmodes,
			filtered = #leaderboard_inputmodes,
		}}
	end

	local inputmodes = Inputmodes:entries_to_list(leaderboard_inputmodes)

	return {json = {
		total = #inputmodes,
		filtered = #inputmodes,
		inputmodes = inputmodes
	}}
end

return leaderboard_inputmodes_c
