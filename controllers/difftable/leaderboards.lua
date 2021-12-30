local Leaderboard_difftables = require("models.leaderboard_difftables")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local difftable_leaderboards_c = Controller:new()

difftable_leaderboards_c.path = "/difftables/:difftable_id[%d]/leaderboards"
difftable_leaderboards_c.methods = {"GET"}

difftable_leaderboards_c.context.GET = {"difftable"}
difftable_leaderboards_c.policies.GET = {{"permit"}}
difftable_leaderboards_c.GET = function(request)
	local params = request.params
	local leaderboard_difftables = Leaderboard_difftables:find_all({params.difftable_id}, "difftable_id")

	if params.no_data then
		return {json = {
			total = #leaderboard_difftables,
			filtered = #leaderboard_difftables,
		}}
	end

	preload(leaderboard_difftables, "leaderboard")

	local leaderboards = {}
	for _, leaderboard_difftable in ipairs(leaderboard_difftables) do
		table.insert(leaderboards, leaderboard_difftable.leaderboard)
	end

	return {json = {
		total = #leaderboards,
		filtered = #leaderboards,
		leaderboards = leaderboards
	}}
end

return difftable_leaderboards_c
