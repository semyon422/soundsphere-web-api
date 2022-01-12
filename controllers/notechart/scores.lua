local Scores = require("models.scores")
local User_relations = require("models.user_relations")
local Leaderboard_scores = require("models.leaderboard_scores")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local notechart_scores_c = Controller:new()

notechart_scores_c.path = "/notecharts/:notechart_id[%d]/scores"
notechart_scores_c.methods = {"GET"}

notechart_scores_c.get_relations_scores = function(params, relationtype, mutual)
	local user_id = tonumber(params[relationtype .. "s"])

	local user_ids = {user_id}
	local user_relations = User_relations:find_all(
		user_ids,
		"user_id",
		{where = {relationtype = User_relations.types[relationtype]}}
	)
	for _, user_relation in ipairs(user_relations) do
		table.insert(user_ids, user_relation.relative_user_id)
	end

	local leaderboard_scores = Leaderboard_scores:find_all(
		user_ids,
		"user_id",
		{where = {
			notechart_id = params.notechart_id,
			mutual = mutual
		}}
	)
	preload(leaderboard_scores, {"score"})

	local scores = {}
	for _, leaderboard_score in ipairs(leaderboard_scores) do
		table.insert(scores, leaderboard_score.score)
	end

	return scores
end

notechart_scores_c.get_scores = function(self)
	local params = self.params
	local db = Scores.db

	local clause_table = {"s"}
	local where_table = {"s.notechart_id = ?", "s.is_valid = ?", "s.is_complete = ?"}
	local fields = {"s.*"}
	local orders = {}
	local opts = {params.notechart_id, true, true}

	if params.leaderboard_id then
		table.insert(clause_table, "inner join leaderboard_users lu on s.user_id = lu.user_id")
		table.insert(where_table, "lu.active = true")
		table.insert(where_table, "lu.leaderboard_id = ?")
		table.insert(opts, params.leaderboard_id)
	end
	if params.search then
		table.insert(clause_table, "inner join users u on s.user_id = u.id")
		table.insert(where_table, util.db_search(db, params.search, "u.name"))
	end
	table.insert(orders, "s.rating desc")

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

	return scores, clause
end

notechart_scores_c.policies.GET = {{"permit"}}
notechart_scores_c.validations.GET = {
	{"rivals", type = "boolean", optional = true},
	{"friends", type = "boolean", optional = true},
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
	require("validations.search"),
	{"leaderboard_id", exists = true, type = "number", optional = true, default = ""},
}
util.add_belongs_to_validations(Scores.relations, notechart_scores_c.validations.GET)
notechart_scores_c.GET = function(self)
	local params = self.params
	local scores

	local clause
	if params.rivals then
		scores = notechart_scores_c.get_relations_scores(params, "rival")
	elseif params.friends then
		scores = notechart_scores_c.get_relations_scores(params, "friend", true)
	else
		scores, clause = notechart_scores_c.get_scores(self)
	end

	local total_clause = Scores.db.encode_clause({
		notechart_id = params.notechart_id,
		is_valid = params.is_valid,
		is_complete = params.is_complete,
	})

	if params.no_data then
		return {json = {
			total = tonumber(Scores:count(total_clause)),
			filtered = not clause and #scores or tonumber(util.db_count(Scores, clause)),
		}}
	end

	preload(scores, util.get_relatives_preload(Scores, params))
	util.recursive_to_name(scores)

	return {json = {
		total = tonumber(Scores:count(total_clause)),
		filtered = not clause and #scores or tonumber(util.db_count(Scores, clause)),
		scores = scores,
	}}
end

return notechart_scores_c
