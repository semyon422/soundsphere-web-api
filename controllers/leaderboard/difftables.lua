local Leaderboard_difftables = require("models.leaderboard_difftables")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local leaderboard_difftables_c = Controller:new()

leaderboard_difftables_c.path = "/leaderboards/:leaderboard_id[%d]/difftables"
leaderboard_difftables_c.methods = {"GET"}

leaderboard_difftables_c.policies.GET = {{"permit"}}
leaderboard_difftables_c.validations.GET = {
	require("validations.no_data"),
}
leaderboard_difftables_c.GET = function(self)
	local params = self.params
    local leaderboard_difftables = Leaderboard_difftables:find_all({params.leaderboard_id}, "leaderboard_id")

	if params.no_data then
		return {json = {
			total = #leaderboard_difftables,
			filtered = #leaderboard_difftables,
		}}
	end

	preload(leaderboard_difftables, "difftable")

	local difftables = {}
	for _, leaderboard_difftable in ipairs(leaderboard_difftables) do
		table.insert(difftables, leaderboard_difftable.difftable)
	end

	return {json = {
		total = #difftables,
		filtered = #difftables,
		difftables = difftables
	}}
end

return leaderboard_difftables_c
