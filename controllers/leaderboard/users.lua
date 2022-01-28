local Leaderboard_users = require("models.leaderboard_users")
local Joined_query = require("util.joined_query")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local leaderboard_users_c = Controller:new()

leaderboard_users_c.path = "/leaderboards/:leaderboard_id[%d]/users"
leaderboard_users_c.methods = {"GET"}

leaderboard_users_c.get_users = function(self)
	local params = self.params
	local db = Leaderboard_users.db

	local jq = Joined_query:new(db)
	jq:select("lu")
	jq:where("lu.active = ?", true)
	jq:where("lu.leaderboard_id = ?", params.leaderboard_id)
	jq:fields("lu.*")

	if params.community_id then
		jq:select("inner join community_users cu on lu.user_id = cu.user_id")
		jq:where("cu.accepted = ?", true)
		jq:where("cu.community_id = ?", params.community_id)
	end
	if params.search then
		jq:select("inner join users u on lu.user_id = u.id")
		jq:where(util.db_search(db, params.search, "name"))
	end

	jq:orders("lu.total_rating desc")
	jq:orders("lu.user_id asc")

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local query, options = jq:concat()
	options.per_page = per_page

	local paginator = Leaderboard_users:paginated(query, options)
	local leaderboard_users = paginator:get_page(page_num)

	for i, leaderboard_user in ipairs(leaderboard_users) do
		leaderboard_user.rank = (page_num - 1) * per_page + i
	end

	return leaderboard_users, query
end

leaderboard_users_c.policies.GET = {{"permit"}}
leaderboard_users_c.validations.GET = {
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
	{"community_id", exists = true, type = "number", optional = true, default = ""},
}
util.add_belongs_to_validations(Leaderboard_users.relations, leaderboard_users_c.validations.GET)
leaderboard_users_c.GET = function(self)
	local params = self.params

	local leaderboard_users, filtered_clause = leaderboard_users_c.get_users(self)

	local db = Leaderboard_users.db
	local total_clause = db.encode_clause({
		leaderboard_id = params.leaderboard_id,
		active = true,
	})

	if params.no_data then
		return {json = {
			total = tonumber(Leaderboard_users:count(total_clause)),
			filtered = tonumber(util.db_count(Leaderboard_users, filtered_clause)),
		}}
	end

	preload(leaderboard_users, util.get_relatives_preload(Leaderboard_users, params))
	util.recursive_to_name(leaderboard_users)

	return {json = {
		total = tonumber(Leaderboard_users:count(total_clause)),
		filtered = tonumber(util.db_count(Leaderboard_users, filtered_clause)),
		leaderboard_users = leaderboard_users,
	}}
end

return leaderboard_users_c
