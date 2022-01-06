local Community_inputmodes = require("models.community_inputmodes")
local Community_leaderboards = require("models.community_leaderboards")
local Inputmodes = require("enums.inputmodes")
local array_update = require("util.array_update")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload

local community_inputmodes_c = Controller:new()

community_inputmodes_c.path = "/communities/:community_id[%d]/inputmodes"
community_inputmodes_c.methods = {"GET"}

community_inputmodes_c.policies.GET = {{"permit"}}
community_inputmodes_c.validations.GET = {
	require("validations.no_data"),
}
community_inputmodes_c.GET = function(self)
	local params = self.params

	local community_leaderboards = Community_leaderboards:find_all({params.community_id}, "community_id")
	preload(community_leaderboards, {leaderboard = "leaderboard_inputmodes"})

	local leaderboard_inputmodes = {}
	for _, community_leaderboard in ipairs(community_leaderboards) do
		for _, leaderboard_inputmode in ipairs(community_leaderboard.leaderboard.leaderboard_inputmodes) do
			table.insert(leaderboard_inputmodes, leaderboard_inputmode)
		end
	end

	local new_inputmodes, old_inputmodes, all_inputmodes = array_update(
		leaderboard_inputmodes,
		Community_inputmodes:find_all({params.community_id}, "community_id"),
		function(li) return li.inputmode end,
		function(ci) return ci.inputmode end
	)

	local db = Community_inputmodes.db
	if #old_inputmodes > 0 then
		db.delete("community_inputmodes", {inputmode = db.list(old_inputmodes)})
	end
	for _, inputmode in ipairs(new_inputmodes) do
		db.insert("community_inputmodes", {
			community_id = params.community_id,
			inputmode = inputmode,
		})
	end

	if params.no_data then
		return {json = {
			total = #all_inputmodes,
			filtered = #all_inputmodes,
		}}
	end

	local inputmodes = {}
	for _, inputmode in ipairs(all_inputmodes) do
		table.insert(inputmodes, Inputmodes:to_name(inputmode))
	end

	return {json = {
		total = #inputmodes,
		filtered = #inputmodes,
		inputmodes = inputmodes,
	}}
end

return community_inputmodes_c
