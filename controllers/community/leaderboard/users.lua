local Community_users = require("models.community_users")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local community_leaderboard_users_c = Controller:new()

community_leaderboard_users_c.path = "/communities/:community_id[%d]/leaderboards/:leaderboard_id[%d]/users"
community_leaderboard_users_c.methods = {"GET"}

community_leaderboard_users_c.policies.GET = {{"permit"}}
community_leaderboard_users_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
}
util.add_belongs_to_validations(Community_users.relations, community_leaderboard_users_c.validations.GET)
community_leaderboard_users_c.GET = function(self)
	local params = self.params

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local paginator = Community_users:paginated(
		[[cu inner join leaderboard_users lu on cu.user_id = lu.user_id
		where cu.community_id = ? and lu.leaderboard_id = ? order by total_rating desc, user_id asc]],
		params.community_id, params.leaderboard_id,
		{
			per_page = per_page,
			fields = "cu.user_id, lu.total_rating"
		}
	)
	local community_users = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	preload(community_users, util.get_relatives_preload(Community_users, params))
	util.recursive_to_name(community_users)

	for i, community_user in ipairs(community_users) do
		community_user.rank = (page_num - 1) * per_page + i
	end

	return {json = {community_users = community_users}}
end

return community_leaderboard_users_c
