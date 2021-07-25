local Scores = require("models.scores")
local User_rivals = require("models.user_rivals")
local Leaderboard_scores = require("models.leaderboard_scores")
local preload = require("lapis.db.model").preload

local notechart_c = {}

local function get_rivals_scores(params)
	local user_id = tonumber(params.rivals)

	local rival_ids = {user_id}
	local user_rivals = User_rivals:find_all(rival_ids, "user_id")
	for _, user_rival in ipairs(user_rivals) do
		table.insert(rival_ids, user_rival.rival_id)
	end

	local leaderboard_scores = Leaderboard_scores:find_all(
		rival_ids,
		"user_id",
		{where = {notechart_id = params.notechart_id}}
	)
	preload(leaderboard_scores, {"user", "score"})

	local scores = {}
	for _, leaderboard_score in ipairs(leaderboard_scores) do
		local user = leaderboard_score.user
		local score = leaderboard_score.score
		score.user = {
			id = user.id,
			name = user.name,
			tag = user.tag,
			latest_activity = user.latest_activity,
		}
		table.insert(scores, score)
	end
	return scores
end

notechart_c.GET = function(params)
	local scores
	if params.rivals then
		scores = get_rivals_scores(params)
	else
		scores = Scores:find_all({params.notechart_id}, "notechart_id")
	end

	local count = #scores

	return 200, {
		total = count,
		filtered = count,
		scores = scores
	}
end

return notechart_c
