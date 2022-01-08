local Leaderboard_difftables = require("models.leaderboard_difftables")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local leaderboard_difftables_c = Controller:new()

leaderboard_difftables_c.path = "/leaderboards/:leaderboard_id[%d]/difftables"
leaderboard_difftables_c.methods = {"GET"}

leaderboard_difftables_c.policies.GET = {{"permit"}}
leaderboard_difftables_c.validations.GET = {
	require("validations.no_data"),
}
leaderboard_difftables_c.validations.GET = util.add_belongs_to_validations(Leaderboard_difftables.relations)
leaderboard_difftables_c.GET = function(self)
	local params = self.params
    local leaderboard_difftables = Leaderboard_difftables:find_all({params.leaderboard_id}, "leaderboard_id")

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
		difftables = leaderboard_difftables,
	}}
end

return leaderboard_difftables_c
