local Leaderboards = require("models.leaderboards")
local leaderboard_tables_c = require("controllers.leaderboard.tables")
local leaderboard_communities_c = require("controllers.leaderboard.communities")
local leaderboard_users_c = require("controllers.leaderboard.users")

local leaderboard_c = {}

leaderboard_c.GET = function(params)
	local leaderboard = Leaderboards:find(params.leaderboard_id)

	if params.tables then
		local _, response = leaderboard_tables_c.GET(params)
		leaderboard.tables = response.tables
		leaderboard.tables_count = response.total
	end
	if params.communities then
		local _, response = leaderboard_communities_c.GET(params)
		leaderboard.communities = response.communities
		leaderboard.communities_count = response.total
	end
	if params.users then
		local _, response = leaderboard_users_c.GET(params)
		leaderboard.users = response.users
		leaderboard.users_count = response.total
	end

	return 200, {leaderboard = leaderboard}
end

leaderboard_c.PATCH = function(params)
	local leaderboard = Leaderboards:find(params.leaderboard_id)

	leaderboard.name = params.leaderboard.name
	leaderboard.description = params.leaderboard.description

	leaderboard:update("name", "description")

	return 200, {leaderboard = leaderboard}
end

return leaderboard_c
