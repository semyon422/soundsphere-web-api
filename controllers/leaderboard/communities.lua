local Community_leaderboards = require("models.community_leaderboards")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local leaderboard_communities_c = Controller:new()

leaderboard_communities_c.path = "/leaderboards/:leaderboard_id[%d]/communities"
leaderboard_communities_c.methods = {"GET"}

leaderboard_communities_c.policies.GET = {{"permit"}}
leaderboard_communities_c.validations.GET = {
	require("validations.no_data"),
}
leaderboard_communities_c.validations.GET = util.add_belongs_to_validations(Community_leaderboards.relations)
leaderboard_communities_c.GET = function(self)
	local params = self.params
    local leaderboard_communities = Community_leaderboards:find_all({params.leaderboard_id}, "leaderboard_id")

	if params.no_data then
		return {json = {
			total = #leaderboard_communities,
			filtered = #leaderboard_communities,
		}}
	end

	preload(leaderboard_communities, util.get_relatives_preload(Community_leaderboards, params))
	util.recursive_to_name(leaderboard_communities)

	return {json = {
		total = #leaderboard_communities,
		filtered = #leaderboard_communities,
		leaderboard_communities = leaderboard_communities,
	}}
end

return leaderboard_communities_c
