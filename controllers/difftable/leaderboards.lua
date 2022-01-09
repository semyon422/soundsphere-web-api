local Leaderboard_difftables = require("models.leaderboard_difftables")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local difftable_leaderboards_c = Controller:new()

difftable_leaderboards_c.path = "/difftables/:difftable_id[%d]/leaderboards"
difftable_leaderboards_c.methods = {"GET"}

difftable_leaderboards_c.context.GET = {"difftable"}
difftable_leaderboards_c.policies.GET = {{"permit"}}
difftable_leaderboards_c.validations.GET = util.add_belongs_to_validations(Leaderboard_difftables.relations)
difftable_leaderboards_c.GET = function(self)
	local params = self.params
	local leaderboard_difftables = Leaderboard_difftables:find_all({params.difftable_id}, "difftable_id")

	if params.no_data then
		return {json = {
			total = #leaderboard_difftables,
			filtered = #leaderboard_difftables,
		}}
	end

	preload(leaderboard_difftables, util.get_relatives_preload(Leaderboard_difftables, params))
	util.recursive_to_name(leaderboard_difftables)

	return {json = {
		total = #leaderboard_difftables,
		filtered = #leaderboard_difftables,
		difftable_leaderboards = leaderboard_difftables,
	}}
end

return difftable_leaderboards_c
