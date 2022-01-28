local Scores = require("models.scores")
local Joined_query = require("util.joined_query")
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
	require("validations.search"),
	{"is_not_complete", type = "boolean", optional = true},
	{"is_not_valid", type = "boolean", optional = true},
	{"latest", type = "boolean", optional = true},
	{"leaderboard_id", exists = true, type = "number", optional = true, default = ""},
	{"difftable_id", exists = true, type = "number", optional = true, default = ""},
}
util.add_belongs_to_validations(Scores.relations, user_scores_c.validations.GET )
user_scores_c.GET = function(self)
	local params = self.params
	local db = Scores.db

	local jq = Joined_query:new(db)
	jq:select("s")
	jq:where("s.user_id = ?", params.user_id)
	jq:where("s.is_complete = ?", not params.is_not_complete)
	jq:where("s.is_valid = ?", not params.is_not_valid)
	jq:fields("s.*")

	if not params.latest then
		jq:where("s.is_top = ?", true)
	end
	if params.leaderboard_id then
		jq:select("inner join leaderboard_scores ls on s.user_id = ls.user_id and s.id = ls.score_id")
		jq:where("s.is_ranked = ?", true)
		jq:where("ls.leaderboard_id = ?", params.leaderboard_id)
		jq:fields("ls.rating as leaderboard_rating")
	end
	if params.difftable_id then
		jq:select("inner join difftable_notecharts dn on s.notechart_id = dn.notechart_id")
		jq:where("dn.difftable_id = ?", params.difftable_id)
	end
	if params.search then
		jq:select("inner join notecharts n on s.notechart_id = n.id")
		jq:where(util.db_search(
			db,
			params.search,
			"n.difficulty_creator",
			"n.difficulty_name",
			"n.song_artist",
			"n.song_title"
		))
	end

	if params.latest then
		jq:orders("s.created_at desc")
	elseif params.leaderboard_id then
		jq:orders("ls.rating desc")
	else
		jq:orders("s.rating desc")
	end

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local query, options = jq:concat()
	options.per_page = per_page

	local paginator = Scores:paginated(query, options)
	local scores = paginator:get_page(page_num)

	for i, score in ipairs(scores) do
		if not params.latest then
			score.rank = (page_num - 1) * per_page + i
		end
		if score.leaderboard_rating then
			score.rating = score.leaderboard_rating
			score.leaderboard_rating = nil
		end
	end

	local total_clause = db.encode_clause({
		user_id = params.user_id,
	})

	if params.no_data then
		return {json = {
			total = tonumber(Scores:count(total_clause)),
			filtered = tonumber(util.db_count(Scores, query)),
		}}
	end

	preload(scores, util.get_relatives_preload(Scores, params))
	util.recursive_to_name(scores)

	return {json = {
		total = tonumber(Scores:count(total_clause)),
		filtered = tonumber(util.db_count(Scores, query)),
		scores = scores,
	}}
end

return user_scores_c
