local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Controller = require("Controller")
local Inputmodes = require("enums.inputmodes")
local util = require("util")
local preload = require("lapis.db.model").preload

local leaderboard_inputmodes_c = Controller:new()

leaderboard_inputmodes_c.path = "/leaderboards/:leaderboard_id[%d]/inputmodes"
leaderboard_inputmodes_c.methods = {"GET", "PATCH"}

leaderboard_inputmodes_c.update_inputmodes = function(leaderboard_id, inputmodes)
	if not inputmodes then
		return
	end

	local leaderboard_inputmodes = Leaderboard_inputmodes:find_all({leaderboard_id}, "leaderboard_id")

	local new_inputmodes, old_inputmodes = util.array_update(
		inputmodes,
		leaderboard_inputmodes,
		function(li) return Inputmodes:for_db(li.inputmode) end,
		function(li) return li.inputmode end
	)

	local db = Leaderboard_inputmodes.db
	if #old_inputmodes > 0 then
		db.delete("leaderboard_inputmodes", {inputmode = db.list(old_inputmodes)})
	end
	for _, inputmode in ipairs(new_inputmodes) do
		db.insert("leaderboard_inputmodes", {
			leaderboard_id = leaderboard_id,
			inputmode = inputmode,
		})
	end
end

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

leaderboard_inputmodes_c.policies.PATCH = {{"permit"}}
leaderboard_inputmodes_c.validations.PATCH = {
	{"leaderboard_inputmodes", exists = true, type = "table", param_type = "body"}
}
leaderboard_inputmodes_c.PATCH = function(self)
	local params = self.params

	leaderboard_inputmodes_c.update_inputmodes(params.leaderboard_id, params.leaderboard_inputmodes)
	local leaderboard_inputmodes = Leaderboard_inputmodes:find_all({params.leaderboard_id}, "leaderboard_id")
	util.recursive_to_name(leaderboard_inputmodes)

	return {json = {
		total = #leaderboard_inputmodes,
		filtered = #leaderboard_inputmodes,
		leaderboard_inputmodes = leaderboard_inputmodes,
	}}
end

return leaderboard_inputmodes_c
