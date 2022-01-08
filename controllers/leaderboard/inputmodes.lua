local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Controller = require("Controller")
local util = require("util")
local preload = require("lapis.db.model").preload

local leaderboard_inputmodes_c = Controller:new()

leaderboard_inputmodes_c.path = "/leaderboards/:leaderboard_id[%d]/inputmodes"
leaderboard_inputmodes_c.methods = {"GET"}

leaderboard_inputmodes_c.policies.GET = {{"permit"}}
leaderboard_inputmodes_c.validations.GET = {
	require("validations.no_data"),
}
util.add_belongs_to_validations(Leaderboard_inputmodes.relations, leaderboard_inputmodes_c.validations.GET)
leaderboard_inputmodes_c.GET = function(self)
	local params = self.params
	local leaderboard_inputmodes = Leaderboard_inputmodes:find_all({params.leaderboard_id}, "leaderboard_id")

	if params.no_data then
		return {json = {
			total = #leaderboard_inputmodes,
			filtered = #leaderboard_inputmodes,
		}}
	end

	preload(leaderboard_inputmodes, util.get_relatives_preload(Leaderboard_inputmodes, params))
	util.recursive_to_name(leaderboard_inputmodes)

	return {json = {
		total = #leaderboard_inputmodes,
		filtered = #leaderboard_inputmodes,
		leaderboard_inputmodes = leaderboard_inputmodes,
	}}
end

return leaderboard_inputmodes_c
