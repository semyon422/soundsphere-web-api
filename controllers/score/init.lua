local Scores = require("models.scores")
local Leaderboard_scores = require("models.leaderboard_scores")
local Files = require("models.files")
local Modifiersets = require("models.modifiersets")
local Controller = require("Controller")
local Formats = require("enums.formats")
local Inputmodes = require("enums.inputmodes")
local util = require("util")
local http = require("lapis.nginx.http")
local config = require("lapis.config").get()
local lapis_util = require("lapis.util")
local to_json = lapis_util.to_json
local from_json = lapis_util.from_json
local preload = require("lapis.db.model").preload
local score_leaderboards_c = require("controllers.score.leaderboards")
local notecharts_c = require("controllers.notecharts")

local additions = {
	leaderboards = score_leaderboards_c,
}

local score_c = Controller:new()

score_c.path = "/scores/:score_id[%d]"
score_c.methods = {"GET", "PATCH", "DELETE"}

score_c.update_stats = function(score, is_valid)
	if not is_valid == not score.is_valid then
		return
	end

	local sign = 0
	if not is_valid and score.is_valid then
		score_c.make_is_top(score)
		sign = 1
	elseif is_valid and not score.is_valid then
		score_c.make_is_not_top(score)
		sign = -1
	end

	local notechart = score:get_notechart()
	local user = score:get_user()

	user.notes_count = math.max(user.notes_count + notechart.notes_count * sign, 0)
	user.play_time = math.max(user.play_time + notechart.length * sign, 0)
	user.scores_count = math.max(user.scores_count + sign, 0)
	user:update(
		"scores_count",
		"notes_count",
		"play_time"
	)

	-- can be bugged because of changed difftable_notecharts
	local difftable_notecharts = notechart:get_difftable_notecharts()
	preload(difftable_notecharts, "difftable")
	for _, difftable_notechart in ipairs(difftable_notecharts) do
		local difftable = difftable_notechart.difftable
		difftable.scores_count = math.max(difftable.scores_count + sign, 0)
		difftable:update("scores_count")
	end
end

score_c.make_is_top = function(score)
	if score.is_top then
		return
	end

	local top_score = Scores:find({
		notechart_id = score.notechart_id,
		user_id = score.user_id,
		is_top = true,
	})

	if not top_score then
		local user = score:get_user()
		user.notecharts_count = user.notecharts_count + 1
		user:update("notecharts_count")
	end
	if not top_score or score.rating > top_score.rating then
		score.is_top = true
		score:update("is_top")
	end
	if top_score and score.rating > top_score.rating then
		top_score.is_top = false
		top_score:update("is_top")
	end
end

score_c.make_is_not_top = function(score)
	if not score.is_top then
		return
	end

	score.is_top = false
	score:update("is_top")

	local top_score = Scores:select(
		"where id != ? and notechart_id = ? and user_id = ? order by rating desc limit 1",
		score.id, score.notechart_id, score.user_id
	)[1]
	if top_score then
		top_score.is_top = true
		top_score:update("is_top")
		return
	end

	local user = score:get_user()
	user.notecharts_count = math.max(user.notecharts_count - 1, 0)
	user:update("notecharts_count")
end

score_c.context.GET = {"score"}
score_c.policies.GET = {{"permit"}}
score_c.validations.GET = {}
util.add_additions_validations(additions, score_c.validations.GET)
util.add_belongs_to_validations(Scores.relations, score_c.validations.GET)
score_c.GET = function(self)
	local score = self.context.score

	util.load_additions(self, score, additions)
	util.get_relatives(score, self.params, true)

	return {json = {score = score:to_name()}}
end

score_c.process_score = function(score)
	local notechart = score:get_notechart()
	if not notechart.is_valid then
		return false, 400, "not notechart.is_valid"
	end

	local replay_file = score:get_file()
	if not replay_file then
		score.is_complete = true
		score.is_valid = false
		score:update("is_complete", "is_valid")
		return false, 400, "not replay_file"
	elseif not replay_file.uploaded then
		return false, 400, "not replay_file.uploaded"
	end

	local notechart_file = notechart:get_file()
	if not notechart_file then
		score.is_complete = true
		score.is_valid = false
		score:update("is_complete", "is_valid")
		return false, 400, "not notechart_file"
	end

	notecharts_c.process_ranked_cache(notechart_file)

	local body, status_code, headers = http.simple({
		url = ("http://127.0.0.1:%d/replay"):format(config.game_server_port),
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
		return false, 500, "Compute server is not available"
	end

	if status_code == 500 then  -- Internal Server Error
		score.is_complete = true
		score.is_valid = false
		score:update("is_complete", "is_valid")
		return false, status_code, "Invalid score" .. body
	end

	if status_code ~= 200 then
		return false, status_code, body
	end

	local json_response = from_json(body)
	local response_score = json_response.score

	if response_score.base.progress < 0.99 then
		score.is_complete = true
		score.is_valid = false
		score:update("is_complete", "is_valid")
		return false, 400, "Incomplete score"
	end

	local encoded = json_response.modifiersEncoded
	local displayed = json_response.modifiersString
	if #encoded >= 255 or #displayed >= 255 then
		score.is_complete = true
		score.is_valid = false
		score:update("is_complete", "is_valid")
		return false, 400, "Invalid modifiers"
	end
	local new_modifierset = {
		encoded = encoded,
	}
	local modifierset = Modifiersets:find(new_modifierset)
	if not modifierset then
		new_modifierset.displayed = displayed
		new_modifierset.timerate = response_score.base.timeRate
		modifierset = Modifiersets:create(new_modifierset)
	else
		modifierset.displayed = displayed
		modifierset.timerate = response_score.base.timeRate
		modifierset:update("displayed", "timerate")
	end

	local inputmode = Inputmodes[json_response.inputMode] and json_response.inputMode or "undefined"
	local inputmode_for_db = Inputmodes:for_db(inputmode)

	local rating = response_score.normalscore.rating32
	local difficulty = response_score.normalscore.enps
	local misses_count = response_score.base.missCount
	local accuracy = response_score.normalscore.accuracyAdjusted
	if
		misses_count > notechart.notes_count / 2 or
		modifierset.timerate < 0.25 or modifierset.timerate > 4 or
		accuracy == 0 or
		accuracy > 0.1
	then
		rating = 0
		difficulty = 0
	end

	score.modifierset_id = modifierset.id
	score.inputmode = inputmode_for_db
	score.is_complete = true
	score.is_valid = true
	score.score = response_score.normalscore.scoreAdjusted
	score.accuracy = accuracy
	score.max_combo = response_score.base.maxCombo
	score.misses_count = misses_count
	score.difficulty = difficulty
	score.rating = rating
	score:update(
		"modifierset_id",
		"inputmode",
		"is_complete",
		"is_valid",
		"score",
		"accuracy",
		"max_combo",
		"misses_count",
		"difficulty",
		"rating"
	)

	replay_file.loaded = true
	replay_file:update("loaded")

	local latest_score = Scores:select(
		"where user_id = ? and is_ranked = ? order by created_at desc limit 1",
		score.user_id,
		true
	)[1]
	if latest_score then
		local user = score:get_user()
		user.latest_score_submitted_at = latest_score.created_at
		user.latest_activity = math.max(user.latest_activity, user.latest_score_submitted_at)
		user:update("latest_score_submitted_at", "latest_activity")
	end

	score.modifierset = modifierset

	return true
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

	local is_valid = score.is_valid
	local success, code, message = score_c.process_score(score)
	score_c.update_stats(score, is_valid)
	if not success then
		return {status = code, json = {message = message}}
	end
	score.file = nil
	score.notechart = nil
	score.user = nil

	return {json = {score = score:to_name()}}
end

score_c.context.DELETE = {"score", "request_session", "session_user", "user_roles"}
score_c.policies.DELETE = {
	{"authed", {role = "donator"}},
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
	notechart.scores_count = math.max(notechart.scores_count - 1, 0)
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
			user.notecharts_count = math.max(user.notecharts_count - 1, 0)
			user:update("notecharts_count")
		end
	end
	user.notes_count = math.max(user.notes_count - notechart.notes_count, 0)
	user.play_time = math.max(user.play_time - notechart.length, 0)
	user.scores_count = math.max(user.scores_count - 1, 0)
	user:update(
		"scores_count",
		"notes_count",
		"play_time"
	)

	local leaderboard_scores = Leaderboard_scores:find_all({score.id}, "score_id")
	preload(leaderboard_scores, "leaderboard")
	for _, leaderboard_score in ipairs(leaderboard_scores) do
		score_leaderboards_c.update_user_leaderboard(user.id, leaderboard_score.leaderboard)
		leaderboard_score:delete()
	end

	score:delete()

	return {status = 204}
end

return score_c
