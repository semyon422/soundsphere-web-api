local Leaderboard_difftables = require("models.leaderboard_difftables")

local leaderboard_difftable_c = {}

leaderboard_difftable_c.path = "/leaderboards/:leaderboard_id/difftables/:difftable_id"
leaderboard_difftable_c.methods = {"PUT", "DELETE"}
leaderboard_difftable_c.context = {"leaderboard", "difftable"}
leaderboard_difftable_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
}

leaderboard_difftable_c.PUT = function(request)
	local params = request.params
    local leaderboard_difftable = {
        leaderboard_id = params.leaderboard_id,
        difftable_id = params.difftable_id,
    }
    if not Leaderboard_difftables:find(leaderboard_difftable) then
        Leaderboard_difftables:create(leaderboard_difftable)
    end

	return 200, {}
end

leaderboard_difftable_c.DELETE = function(request)
	local params = request.params
    local leaderboard_difftable = Leaderboard_difftables:find({
        leaderboard_id = params.leaderboard_id,
        difftable_id = params.difftable_id,
    })
    if leaderboard_difftable then
        leaderboard_difftable:delete()
    end

	return 200, {}
end

return leaderboard_difftable_c
