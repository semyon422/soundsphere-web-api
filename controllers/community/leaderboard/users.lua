local Community_users = require("models.community_users")
local Users = require("models.users")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local community_leaderboard_users_c = Controller:new()

community_leaderboard_users_c.path = "/communities/:community_id[%d]/leaderboards/:leaderboard_id[%d]/users"
community_leaderboard_users_c.methods = {"GET"}

community_leaderboard_users_c.policies.GET = {{"permit"}}
community_leaderboard_users_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
}
community_leaderboard_users_c.GET = function(request)
	local params = request.params

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local paginator = Community_users:paginated(
		[[cu inner join leaderboard_users lu on cu.user_id = lu.user_id
		where cu.community_id = ? and lu.leaderboard_id = ? order by total_performance desc, user_id asc]],
		params.community_id, params.leaderboard_id,
		{
			per_page = per_page,
			page_num = page_num,
			fields = "cu.user_id, lu.total_performance"
		}
	)
	local community_leaderboard_users = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	preload(community_leaderboard_users, "user")

	local users = {}
	for i, community_leaderboard_user in ipairs(community_leaderboard_users) do
		local user = community_leaderboard_user.user:to_name()
		user.total_performance = community_leaderboard_user.total_performance
		user.rank = (page_num - 1) * per_page + i
		table.insert(users, user)
	end

	return {json = {users = users}}
end

return community_leaderboard_users_c
