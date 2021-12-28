local Leaderboard_difftables = require("models.leaderboard_difftables")
local Controller = require("Controller")

local leaderboard_difftable_c = Controller:new()

leaderboard_difftable_c.path = "/leaderboards/:leaderboard_id[%d]/difftables/:difftable_id[%d]"
leaderboard_difftable_c.methods = {"PUT", "DELETE"}

leaderboard_difftable_c.context.PUT = {"leaderboard_difftable", "request_session"}
leaderboard_difftable_c.policies.PUT = {{"authenticated"}}
leaderboard_difftable_c.PUT = function(request)
	local params = request.params

    local leaderboard_difftable = request.context.leaderboard_difftable
	if not leaderboard_difftable then
        leaderboard_difftable = Leaderboard_difftables:create({
			leaderboard_id = params.leaderboard_id,
			difftable_id = params.difftable_id,
		})
	end

	return 200, {leaderboard_difftable = leaderboard_difftable}
end

leaderboard_difftable_c.context.DELETE = {"leaderboard_difftable", "request_session"}
leaderboard_difftable_c.policies.DELETE = {{"authenticated", "context_loaded"}}
leaderboard_difftable_c.DELETE = function(request)
	local params = request.params
    local leaderboard_difftable = request.context.leaderboard_difftable
    leaderboard_difftable:delete()

	return 200, {}
end

return leaderboard_difftable_c
