local leaderboards = require "controllers.community.leaderboards"
local leaderboards = {}

function leaderboards.response(response, request)
	local params = request.params
	return {
		draw = params.draw,
		recordsTotal = response.total,
		recordsFiltered = response.filtered,
		data = response.leaderboards,
	}
end

return leaderboards
