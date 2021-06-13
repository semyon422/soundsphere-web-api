local leaderboards = require("models.leaderboards")

local context_loader = {}

function context_loader:load_context(context)
	if context.leaderboard then return print("context.leaderboard") end
	local leaderboard_id = context.req.params.leaderboard_id
	if leaderboard_id then
		context.leaderboard = leaderboards:find(leaderboard_id)
	end
end

return context_loader