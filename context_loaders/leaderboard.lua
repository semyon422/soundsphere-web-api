local Leaderboards = require("models.leaderboards")

local context_loader = {}

function context_loader:load_context(request)
	if request.context.leaderboard then return print("context.leaderboard") end
	local leaderboard_id = request.params.leaderboard_id
	if leaderboard_id then
		request.context.leaderboard = Leaderboards:find(leaderboard_id)
	end
end

return context_loader
