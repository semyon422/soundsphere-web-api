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
    local community_leaderboards = Community_leaderboards:find_all({params.leaderboard_id}, {
		key = "leaderboard_id",
		where = {accepted = true},
	})

	if params.no_data then
		return {json = {
			total = #community_leaderboards,
			filtered = #community_leaderboards,
		}}
	end

	preload(community_leaderboards, util.get_relatives_preload(Community_leaderboards, params))
	util.recursive_to_name(community_leaderboards)

	for i, leaderboard_community in ipairs(community_leaderboards) do
		leaderboard_community.rank = i
	end

	util.get_methods_for_objects(
		self,
		community_leaderboards,
		require("controllers.community.leaderboard"),
		"community_leaderboard",
		function(params, community_leaderboard)
			params.community_id = community_leaderboard.community_id
		end
	)

	return {json = {
		total = #community_leaderboards,
		filtered = #community_leaderboards,
		community_leaderboards = community_leaderboards,
	}}
end

return leaderboard_communities_c
