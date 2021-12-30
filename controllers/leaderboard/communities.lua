local Community_leaderboards = require("models.community_leaderboards")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local leaderboard_communities_c = Controller:new()

leaderboard_communities_c.path = "/leaderboards/:leaderboard_id[%d]/communities"
leaderboard_communities_c.methods = {"GET"}

leaderboard_communities_c.policies.GET = {{"permit"}}
leaderboard_communities_c.validations.GET = {
	require("validations.no_data"),
}
leaderboard_communities_c.GET = function(self)
	local params = self.params
    local leaderboard_communities = Community_leaderboards:find_all({params.leaderboard_id}, "leaderboard_id")

	if params.no_data then
		return {json = {
			total = #leaderboard_communities,
			filtered = #leaderboard_communities,
		}}
	end

	preload(leaderboard_communities, "leaderboard", "community")

	local communities = {}
	for _, community_leaderboard in ipairs(leaderboard_communities) do
		table.insert(communities, community_leaderboard.community)
	end

	return {json = {
		total = #communities,
		filtered = #communities,
		communities = communities
	}}
end

return leaderboard_communities_c
