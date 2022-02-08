local Leaderboard_scores = require("models.leaderboard_scores")
local Leaderboards = require("models.leaderboards")
local preload = require("lapis.db.model").preload
local util = require("util")
local Controller = require("Controller")

local notechart_leaderboards_c = Controller:new()

notechart_leaderboards_c.path = "/notecharts/:notechart_id[%d]/leaderboards"
notechart_leaderboards_c.methods = {"GET"}

notechart_leaderboards_c.policies.GET = {{"permit"}}
notechart_leaderboards_c.validations.GET = {
	require("validations.no_data"),
}
util.add_belongs_to_validations(Leaderboard_scores.relations, notechart_leaderboards_c.validations.GET)
util.add_has_many_validations(Leaderboards.relations, notechart_leaderboards_c.validations.GET)
notechart_leaderboards_c.GET = function(self)
	local params = self.params

	local leaderboard_scores = Leaderboard_scores:select(
		"where notechart_id = ?", params.notechart_id,
		{fields = "distinct leaderboard_id, notechart_id"}
	)

	if params.no_data then
		return {json = {
			total = #leaderboard_scores,
			filtered = #leaderboard_scores,
		}}
	end

	preload(leaderboard_scores, util.get_relatives_preload(Leaderboard_scores, params))
	util.relatives_preload_field(leaderboard_scores, "leaderboard", Leaderboards, params)
	util.recursive_to_name(leaderboard_scores)

	return {json = {
		total = #leaderboard_scores,
		filtered = #leaderboard_scores,
		leaderboard_scores = leaderboard_scores,
	}}
end

return notechart_leaderboards_c
