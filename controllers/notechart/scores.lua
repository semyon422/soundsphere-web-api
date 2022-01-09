local Scores = require("models.scores")
local User_relations = require("models.user_relations")
local Leaderboard_scores = require("models.leaderboard_scores")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local notechart_scores_c = Controller:new()

notechart_scores_c.path = "/notecharts/:notechart_id[%d]/scores"
notechart_scores_c.methods = {"GET"}

local function get_relations_scores(params, relationtype, mutual)
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

notechart_scores_c.policies.GET = {{"permit"}}
notechart_scores_c.validations.GET = {
	{"rivals", type = "boolean", optional = true},
	{"friends", type = "boolean", optional = true},
}
util.add_belongs_to_validations(Scores.relations, notechart_scores_c.validations.GET)
notechart_scores_c.GET = function(self)
	local params = self.params
	local scores
	local notechart_id = params.notechart_id
	if params.rivals then
		scores = get_relations_scores(params, "rival")
	elseif params.friends then
		scores = get_relations_scores(params, "friend", true)
	else
		scores = Scores:find_all({notechart_id}, "notechart_id")
	end

	if params.no_data then
		return {json = {
			total = #scores,
			filtered = #scores,
		}}
	end

	preload(scores, util.get_relatives_preload(Scores, params))
	util.recursive_to_name(scores)

	return {json = {
		total = #scores,
		filtered = #scores,
		scores = scores,
	}}
end

return notechart_scores_c
