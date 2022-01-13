local Scores = require("models.scores")
local User_relations = require("models.user_relations")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local notechart_scores_c = Controller:new()

notechart_scores_c.path = "/notecharts/:notechart_id[%d]/scores"
notechart_scores_c.methods = {"GET"}

notechart_scores_c.get_relations_scores = function(params, relationtype, mutual)
	local user_id = tonumber(params[relationtype .. "s"])

	local user_ids = {user_id}
	local user_relations = User_relations:find_all(user_ids, {
		key = "user_id",
		where = {
			relationtype = User_relations.types[relationtype],
			mutual = mutual,
		},
	})
	for _, user_relation in ipairs(user_relations) do
		table.insert(user_ids, user_relation.relative_user_id)
	end

	local scores = Scores:find_all(user_ids, {
		key = "user_id",
		where = {
			notechart_id = params.notechart_id,
			is_top = true,
		},
	})

	return scores
end

notechart_scores_c.get_scores = function(self)
	local params = self.params
	local db = Scores.db

	local clause_table = {"s"}
	local where_table = {"s.notechart_id = ?", "s.is_valid = ?", "s.is_complete = ?", "s.is_top = ?"}
	local fields = {"s.*", "row_number() over(order by s.rating) row_number"}
	local orders = {}
	local opts = {params.notechart_id, true, true, true}

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

	return scores, clause, table.concat(fields, ", ")
end

notechart_scores_c.policies.GET = {{"permit"}}
notechart_scores_c.validations.GET = {
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
	require("validations.search"),
	{"rivals", type = "boolean", optional = true},
	{"friends", type = "boolean", optional = true},
	{"leaderboard_id", exists = true, type = "number", optional = true, default = ""},
}
util.add_belongs_to_validations(Scores.relations, notechart_scores_c.validations.GET)
notechart_scores_c.GET = function(self)
	local params = self.params
	local scores

	local clause, fields
	if params.rivals then
		scores = notechart_scores_c.get_relations_scores(params, "rival")
	elseif params.friends then
		scores = notechart_scores_c.get_relations_scores(params, "friend", true)
	else
		scores, clause, fields = notechart_scores_c.get_scores(self)
	end

	--[[
		SELECT COUNT(1) as c from `scores` s
		inner join leaderboard_users lu on s.user_id = lu.user_id
		where (s.notechart_id = 1) and (s.is_valid = TRUE) and (s.is_complete = TRUE) and (s.is_top = TRUE) and (lu.active = true) and (lu.leaderboard_id = 1)
		order by s.rating desc
	]]
	local per_page = params.per_page or 10
	local user_id = self.session.user_id
	local row_number, row_page_num
	if user_id and clause then
		local score = Scores.db.select(
			fields .. " from scores " .. clause .. " limit 1"
		)[1]
		if score then
			row_number = tonumber(score.row_number)
			row_page_num = math.floor(row_number / per_page) + 1
		end
	end

	local total_clause = Scores.db.encode_clause({
		notechart_id = params.notechart_id,
		is_valid = params.is_valid,
		is_complete = params.is_complete,
	})

	if params.no_data then
		return {json = {
			row_number = row_number,
			row_page_num = row_page_num,
			total = tonumber(Scores:count(total_clause)),
			filtered = not clause and #scores or tonumber(util.db_count(Scores, clause)),
		}}
	end

	preload(scores, util.get_relatives_preload(Scores, params))
	util.recursive_to_name(scores)

	return {json = {
		row_number = row_number,
		row_page_num = row_page_num,
		total = tonumber(Scores:count(total_clause)),
		filtered = not clause and #scores or tonumber(util.db_count(Scores, clause)),
		scores = scores,
	}}
end

return notechart_scores_c
