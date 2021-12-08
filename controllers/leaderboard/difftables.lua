local Leaderboard_difftables = require("models.leaderboard_difftables")
local preload = require("lapis.db.model").preload

local leaderboard_difftables_c = {}

leaderboard_difftables_c.path = "/leaderboards/:leaderboard_id/difftables"
leaderboard_difftables_c.methods = {"GET"}
leaderboard_difftables_c.context = {}
leaderboard_difftables_c.policies = {
	GET = require("policies.public"),
}

leaderboard_difftables_c.GET = function(request)
	local params = request.params
    local leaderboard_difftables = Leaderboard_difftables:find_all({params.leaderboard_id}, "leaderboard_id")
	preload(leaderboard_difftables, "difftable")

	local difftables = {}
	for _, leaderboard_difftable in ipairs(leaderboard_difftables) do
		table.insert(difftables, leaderboard_difftable.difftable)
	end

	local count = #difftables

	return 200, {
		total = count,
		filtered = count,
		difftables = difftables
	}
end

return leaderboard_difftables_c
