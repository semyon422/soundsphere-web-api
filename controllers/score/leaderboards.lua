local Leaderboard_scores = require("models.leaderboard_scores")
local Community_leaderboards = require("models.community_leaderboards")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload

local score_leaderboards_c = Controller:new()

score_leaderboards_c.path = "/scores/:score_id[%d]/leaderboards"
score_leaderboards_c.methods = {"GET"}

score_leaderboards_c.get_joined = function(self)
	local params = self.params

	local where = {
		score_id = params.score_id,
	}

	local clause = Leaderboard_scores.db.encode_clause(where)
    local score_leaderboards = Leaderboard_scores:select("where " .. clause .. " order by id asc")
	preload(score_leaderboards, {"leaderboard", "notechart"})

	return score_leaderboards
end

score_leaderboards_c.get_available = function(self)
	local score = self.context.score
	local user = score:get_user()
	local community_users = user:get_community_users()
	local community_ids = {}
	for _, community_user in ipairs(community_users) do
		table.insert(community_ids, community_user.community_id)
	end
	local community_leaderboards = Community_leaderboards:find_all(community_ids, "community_id")
	preload(community_leaderboards, {leaderboard = "leaderboard_requirements"})

	return community_leaderboards
end

score_leaderboards_c.context.GET = {"score"}
score_leaderboards_c.policies.GET = {{"context_loaded"}}
score_leaderboards_c.validations.GET = {
	require("validations.no_data"),
	{"available", type = "boolean", optional = true},
}
score_leaderboards_c.GET = function(self)
	local params = self.params

	local score_leaderboards
	if params.available then
		score_leaderboards = score_leaderboards_c.get_available(self)
	else
		score_leaderboards = score_leaderboards_c.get_joined(self)
	end

	if params.no_data then
		return {json = {
			total = #score_leaderboards,
			filtered = #score_leaderboards,
		}}
	end

	local leaderboards = {}
	for _, score_leaderboard in ipairs(score_leaderboards) do
		local leaderboard = score_leaderboard.leaderboard
		-- leaderboard.score_leaderboard = score_leaderboard
		-- score_leaderboard.leaderboard = nil
		table.insert(leaderboards, leaderboard)
	end

	return {json = {
		total = #score_leaderboards,
		filtered = #score_leaderboards,
		leaderboards = leaderboards,
	}}
end

return score_leaderboards_c
