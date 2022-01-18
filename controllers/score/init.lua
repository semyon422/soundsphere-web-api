local Scores = require("models.scores")
local Leaderboard_scores = require("models.leaderboard_scores")
local Files = require("models.files")
local Modifiersets = require("models.modifiersets")
local Controller = require("Controller")
local Formats = require("enums.formats")
local Inputmodes = require("enums.inputmodes")
local util = require("util")
local http = require("lapis.nginx.http")
local lapis_util = require("lapis.util")
local to_json = lapis_util.to_json
local from_json = lapis_util.from_json
local preload = require("lapis.db.model").preload
local score_leaderboards_c = require("controllers.score.leaderboards")

local additions = {
	leaderboards = score_leaderboards_c,
}

local score_c = Controller:new()

score_c.path = "/scores/:score_id[%d]"
score_c.methods = {"GET", "PATCH", "DELETE"}

score_c.update_stats = function(score)
	local notechart = score:get_notechart()
	local user = score:get_user()

	local new_top_score = {
		notechart_id = score.notechart_id,
		user_id = score.user_id,
		is_top = true,
	}
	local top_score = Scores:find(new_top_score)
	if not top_score then
		user.notecharts_count = user.notecharts_count + 1
	end
	if not top_score or score.rating > top_score.rating then
		score.is_top = true
		score:update("is_top")
	end
	if top_score and score.rating > top_score.rating then
		top_score.is_top = false
		top_score:update("is_top")
	end

	user.notes_count = user.notes_count + notechart.notes_count
	user.play_time = user.play_time + notechart.length
	user.scores_count = user.scores_count + 1
	user:update(
		"scores_count",
		"notecharts_count",
		"notes_count",
		"play_time"
	)

	local difftable_notecharts = notechart:get_difftable_notecharts()
	preload(difftable_notecharts, "difftable")
	for _, difftable_notechart in ipairs(difftable_notecharts) do
		local difftable = difftable_notechart.difftable
		difftable.scores_count = difftable.scores_count + 1
		difftable:update("scores_count")
	end
end

score_c.context.GET = {"score"}
score_c.policies.GET = {{"context_loaded"}}
score_c.validations.GET = {}
util.add_additions_validations(additions, score_c.validations.GET)
util.add_belongs_to_validations(Scores.relations, score_c.validations.GET)
score_c.GET = function(self)
	local score = self.context.score

	util.load_additions(self, score, additions)
	util.get_relatives(score, self.params, true)

	return {json = {score = score:to_name()}}
end

score_c.context.PATCH = {"score", "request_session", "session_user", "user_roles"}
score_c.policies.PATCH = {
	{"authed", {not_params = "force"}, "score_owner"},
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
score_c.validations.PATCH = {
	{"force", type = "boolean", optional = true},
}
score_c.PATCH = function(self)
	local params = self.params
	local score = self.context.score

	if score.is_complete and not params.force then
		return {status = 204}
	end

	local notechart = score:get_notechart()
	if not notechart.is_valid then
		return {status = 400, json = {message = "not notechart.is_valid"}}
	end

	local replay_file = score:get_file()
	if not replay_file then
		score.is_complete = true
		score:update("is_complete")
		return {status = 400, json = {message = "not replay_file"}}
	elseif not replay_file.uploaded then
		return {status = 400, json = {message = "not replay_file.uploaded"}}
	end

	local notechart_file = notechart:get_file()
	if not notechart_file then
		score.is_complete = true
		score:update("is_complete")
		return {status = 400, json = {message = "not replay_file"}}
	end

	local body, status_code, headers = http.simple({
		url = "http://127.0.0.1:8082/replay",
		method = "POST",
		headers = {["content-type"] = "application/json"},
		body = to_json({
			notechart = {
				path = Files:get_path(notechart_file),
				extension = Formats:get_extension(notechart_file.format),
				index = notechart.index,
			},
			replay = {
				path = Files:get_path(replay_file)
			},
		})
	})

	if status_code == 502 then  -- Bad Gateway
		return {status = 500, json = {message = "Compute server is not available"}}
	end

	if status_code == 500 then  -- Internal Server Error
		score.is_complete = true
		score:update("is_complete")
		return {status = status_code, json = {message = "Invalid score"}}
	end

	if status_code ~= 200 then
		return {status = status_code, body}
	end

	local json_response = from_json(body)
	local response_score = json_response.score

	local new_modifierset = {
		encoded = json_response.modifiersEncoded,
		displayed = json_response.modifiersString,
	}
	local modifierset = Modifiersets:find(new_modifierset)
	if not modifierset then
		modifierset = Modifiersets:create(new_modifierset)
	end

	local is_valid = score.is_valid

	score.modifierset_id = modifierset.id
	score.inputmode = Inputmodes:for_db(json_response.inputMode)
	score.is_complete = true
	score.is_valid = true
	score.timerate = response_score.base.timeRate
	score.score = response_score.normalscore.scoreAdjusted
	score.accuracy = response_score.normalscore.accuracyAdjusted
	score.max_combo = response_score.base.maxCombo
	score.difficulty = response_score.normalscore.enps
	score.rating = response_score.normalscore.rating32
	score:update(
		"modifierset_id",
		"inputmode",
		"is_complete",
		"is_valid",
		"timerate",
		"score",
		"accuracy",
		"max_combo",
		"difficulty",
		"rating"
	)

	if not is_valid and score.is_valid then
		score_c.update_stats(score)
	end

	-- if score.is_top then
		replay_file.loaded = true
		replay_file:update("loaded")
	-- else
	-- 	Files:delete_file(replay_file)
	-- 	replay_file:delete()
	-- end

	score.file = nil
	score.notechart = nil
	score.user = nil
	score.modifierset = modifierset

	return {json = {score = score:to_name()}}
end

score_c.context.DELETE = {"score", "request_session", "session_user", "user_roles"}
score_c.policies.DELETE = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
score_c.DELETE = function(self)
	local score = self.context.score

	local replay_file = score:get_file()
	if replay_file then
		Files:delete_file(replay_file)
		replay_file:delete()
	end

	local notechart = score:get_notechart()
	notechart.scores_count = notechart.scores_count - 1
	notechart:update("scores_count")

	local user = score:get_user()
	if score.is_top then
		local not_top_score = Scores:select(
			"where notechart_id = ? and user_id = ? and is_top = ? order by rating desc limit 1",
			score.notechart_id,
			score.user_id,
			false
		)[1]
		if not_top_score then
			not_top_score.is_top = true
			not_top_score:update("is_top")
		else
			user.notecharts_count = user.notecharts_count - 1
			user:update("notecharts_count")
		end
	end
	user.notes_count = user.notes_count - notechart.notes_count
	user.play_time = user.play_time - notechart.length
	user.scores_count = user.scores_count - 1
	user:update(
		"scores_count",
		"notes_count",
		"play_time"
	)

	local leaderboard_scores = Leaderboard_scores:find_all({score.id}, "score_id")
	preload(leaderboard_scores, "leaderboard")
	for _, leaderboard_score in ipairs(leaderboard_scores) do
		score_leaderboards_c.update_user_leaderboard(user.id, leaderboard_score.leaderboard)
	end

	score:delete()

	return {status = 204}
end

return score_c
