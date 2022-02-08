local Scores = require("models.scores")
local User_relations = require("models.user_relations")
local Joined_query = require("util.joined_query")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local notechart_scores_c = Controller:new()

notechart_scores_c.path = "/notecharts/:notechart_id[%d]/scores"
notechart_scores_c.methods = {"GET"}

notechart_scores_c.get_relations = function(user_id, relationtype, mutual)
	local user_ids = {user_id}
	local user_relations = User_relations:find_all(user_ids, {
		key = "user_id",
		where = {
			relationtype = User_relations.types:for_db(relationtype),
			mutual = mutual,
		},
	})
	for _, user_relation in ipairs(user_relations) do
		table.insert(user_ids, user_relation.relative_user_id)
	end

	return user_ids
end

notechart_scores_c.get_scores = function(self, user_ids)
	local params = self.params
	local db = Scores.db

	local jq = Joined_query:new(db)
	jq:select("s")
	jq:where("s.notechart_id = ?", params.notechart_id)
	jq:where("s.is_complete = ?", true)
	jq:where("s.is_valid = ?", true)
	jq:where("s.is_top = ?", true)
	jq:fields("s.*")

	if user_ids then
		jq:where({user_id = db.list(user_ids)})
	end

	if params.leaderboard_id then
		jq:select("inner join leaderboard_users lu on s.user_id = lu.user_id")
		jq:where("s.is_ranked = ?", true)
		jq:where("lu.active = ?", true)
		jq:where("lu.leaderboard_id = ?", params.leaderboard_id)
	end
	jq:select("inner join users u on s.user_id = u.id")
	jq:where("not u.is_banned")
	if params.search then
		jq:where(util.db_search(db, params.search, "u.name"))
	end

	jq:orders("s.rating desc")

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local query, options = jq:concat()
	options.per_page = per_page

	local paginator = Scores:paginated(query, options)
	local scores = paginator:get_page(page_num)

	for i, score in ipairs(scores) do
		score.rank = (page_num - 1) * per_page + i
	end

	return scores, query
end

notechart_scores_c.context.GET = {"request_session", "session_user", "user_roles"}
notechart_scores_c.policies.GET = {
	{{not_params = "rivals"}, {not_params = "friends"}},
	{"authed", {not_params = "friends"}},
	{"authed", {role = "donator"}},
}
notechart_scores_c.validations.GET = {
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
	{"rivals", type = "boolean", optional = true},
	{"friends", type = "boolean", optional = true},
	{"leaderboard_id", exists = true, type = "number", optional = true, default = ""},
	{"user_id", exists = true, type = "number", optional = true, default = ""},
}
util.add_belongs_to_validations(Scores.relations, notechart_scores_c.validations.GET)
notechart_scores_c.GET = function(self)
	local params = self.params
	local scores

	local user_id = self.session.user_id
	local user_ids
	local clause
	if params.rivals then
		user_ids = notechart_scores_c.get_relations(user_id, "rival")
	elseif params.friends then
		user_ids = notechart_scores_c.get_relations(user_id, "friend", true)
	elseif params.user_id then
		user_ids = {params.user_id}
	end
	scores, clause = notechart_scores_c.get_scores(self, user_ids)

	local total_clause = Scores.db.encode_clause({
		notechart_id = params.notechart_id,
		is_complete = params.is_complete,
		is_valid = params.is_valid,
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
