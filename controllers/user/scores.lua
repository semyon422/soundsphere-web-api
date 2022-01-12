local Scores = require("models.scores")
local Controller = require("Controller")
local util = require("util")
local preload = require("lapis.db.model").preload

local user_scores_c = Controller:new()

user_scores_c.path = "/users/:user_id[%d]/scores"
user_scores_c.methods = {"GET"}

user_scores_c.policies.GET = {{"permit"}}
user_scores_c.validations.GET = {
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
	require("validations.search"),
	{"is_not_valid", type = "boolean", optional = true},
	{"is_not_complete", type = "boolean", optional = true},
	{"best", type = "boolean", optional = true},
	{"leaderboard_id", exists = true, type = "number", optional = true, default = ""},
	{"difftable_id", exists = true, type = "number", optional = true, default = ""},
}
util.add_belongs_to_validations(Scores.relations, user_scores_c.validations.GET )
user_scores_c.GET = function(self)
	local params = self.params
	local db = Scores.db

	local clause_table = {"s"}
	local where_table = {"s.user_id = ?", "s.is_valid = ?", "s.is_complete = ?"}
	local fields = {"s.*"}
	local orders = {}
	local opts = {params.user_id, not params.is_not_valid, not params.is_not_complete}

	if params.leaderboard_id then
		table.insert(clause_table, "inner join leaderboard_users lu on s.user_id = lu.user_id")
		table.insert(where_table, "lu.active = true")
		table.insert(where_table, "lu.leaderboard_id = ?")
		table.insert(opts, params.leaderboard_id)
	end
	if params.difftable_id then
		table.insert(clause_table, "inner join difftable_notecharts dn on s.notechart_id = dn.notechart_id")
		table.insert(where_table, "dn.difftable_id = ?")
		table.insert(opts, params.difftable_id)
	end
	if params.search then
		table.insert(clause_table, "inner join notecharts n on s.notechart_id = n.id")
		table.insert(where_table, util.db_search(
			db,
			params.search,
			"n.difficulty_creator",
			"n.difficulty_name",
			"n.song_artist",
			"n.song_title"
		))
	end
	if params.best then
		table.insert(orders, "s.rating desc")
	else
		table.insert(orders, "s.created_at desc")
	end

	table.insert(clause_table, util.db_where(util.db_and(where_table)))
	table.insert(clause_table, "order by " .. table.concat(orders, ", "))

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1
	local clause = db.interpolate_query(
		table.concat(clause_table, " "),
		unpack(opts)
	)

	local paginator = Scores:paginated(clause, {
		per_page = per_page,
		fields = table.concat(fields, ", "),
	})
	local scores = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	if params.best then
		for i, score in ipairs(scores) do
			score.rank = (page_num - 1) * per_page + i
		end
	end

	local total_clause = db.encode_clause({
		user_id = params.user_id,
	})

	if params.no_data then
		return {json = {
			total = tonumber(Scores:count(total_clause)),
			filtered = tonumber(util.db_count(Scores, clause)),
		}}
	end

	preload(scores, util.get_relatives_preload(Scores, params))
	util.recursive_to_name(scores)

	return {json = {
		total = tonumber(Scores:count(total_clause)),
		filtered = tonumber(util.db_count(Scores, clause)),
		scores = scores,
	}}
end

return user_scores_c
