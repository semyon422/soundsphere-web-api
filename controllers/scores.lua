local Scores = require("models.scores")
local Files = require("models.files")
local Notecharts = require("models.notecharts")
local Controller = require("Controller")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
local Filehash = require("util.filehash")
local Joined_query = require("util.joined_query")
local Inputmodes = require("enums.inputmodes")
local util = require("util")
local preload = require("lapis.db.model").preload
local notecharts_c = require("controllers.notecharts")
local metrics = require("metrics")
local config = require("lapis.config").get()

local scores_c = Controller:new()

scores_c.path = "/scores"
scores_c.methods = {"GET", "POST", "PATCH", "PUT"}

scores_c.policies.GET = {{"permit"}}
scores_c.validations.GET = {
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
	{"is_not_complete", type = "boolean", optional = true},
	{"is_not_valid", type = "boolean", optional = true},
}
util.add_belongs_to_validations(Scores.relations, scores_c.validations.GET)
util.add_has_many_validations(Scores.relations, scores_c.validations.GET)
scores_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local jq = Joined_query:new(Scores.db)
	jq:select("s")
	jq:where("s.is_complete = ?", not params.is_not_complete)
	jq:where("s.is_valid = ?", not params.is_not_valid)
	jq:orders("s.id asc")
	jq:fields("s.*")

	if params.search then
		jq:select("inner join notecharts n on s.notechart_id = n.id")
		jq:where(util.db_search(
			Scores.db,
			params.search,
			"n.difficulty_creator",
			"n.difficulty_name",
			"n.song_artist",
			"n.song_title"
		))
	end

	local query, options = jq:concat()
	options.per_page = per_page

	if params.no_data then
		return {json = {
			total = tonumber(Scores:count()),
			filtered = tonumber(util.db_count(Scores, query)),
		}}
	end

	local paginator = Scores:paginated(query, options)
	local scores = paginator:get_page(page_num)

	preload(scores, util.get_relatives_preload(Scores, params))
	util.recursive_to_name(scores)

	return {
		json = {
			total = tonumber(Scores:count()),
			filtered = tonumber(util.db_count(Scores, query)),
			scores = scores,
		}
	}
end

scores_c.context.POST = {"request_session", "session_user", "user_roles", "user_latest_score"}
scores_c.policies.POST = {
	{"authed", "session_user_is_banned_deny"},
	{"authed", {not_params = "trusted"}, "score_submit_limit"},
	{"authed", {role = "moderator"}, "score_submit_limit"},
	{"authed", {role = "admin"}, "score_submit_limit"},
	{"authed", {role = "creator"}, "score_submit_limit"},
}
scores_c.validations.POST = {
	{"trusted", type = "boolean", optional = true},
	{"replay_hash", type = "string", param_type = "body", min_length = 32, max_length = 32},
	{"notechart_hash", type = "string", param_type = "body", min_length = 32, max_length = 32},
	{"notechart_index", type = "number", param_type = "body"},
	{"notechart_filename", type = "string", param_type = "body"},
}
scores_c.POST = function(self)
	local params = self.params

	if not config.is_score_submit_enabled then
		return {status = 403, json = {message = "Score submission is disabled"}}
	end

	local created_at = os.time()
	local hash_for_db = Filehash:for_db(params.notechart_hash)
	local format_for_db = Formats:get_format_for_db(params.notechart_filename)
	local format = Formats:to_name(format_for_db)

	local notechart_file = Files:find({
		hash = hash_for_db
	})
	if not notechart_file then
		local trusted, message = notecharts_c.check_notechart(
			self,
			params.notechart_hash,
			format,
			params.trusted
		)
		if not trusted then
			if metrics.scores then
				metrics.scores:observe(1, {false})
			end
			return {status = 400, json = {message = message}}
		end

		notechart_file = Files:create({
			hash = hash_for_db,
			name = params.notechart_filename,
			format = Formats:get_format_for_db(params.notechart_filename),
			storage = Storages:for_db("notecharts"),
			uploaded = false,
			size = 0,
			loaded = false,
			created_at = created_at,
		})
		if Files:exists(notechart_file) then
			notechart_file.uploaded = true
			notechart_file:update("uploaded")
		end
	end
	if metrics.scores then
		metrics.scores:observe(1, {true})
	end

	local notechart = Notecharts:find({
		file_id = notechart_file.id,
		index = params.notechart_index,
	})
	if not notechart then
		notechart = Notecharts:create({
			file_id = notechart_file.id,
			index = params.notechart_index,
			created_at = created_at,
			scores_count = 0,
			inputmode = Inputmodes:for_db("undefined"),
			difficulty = 0,
			song_title = "",
			song_artist = "",
			difficulty_name = "",
			difficulty_creator = "",
		})
	end

	local replay_file = Files:find({
		hash = Filehash:for_db(params.replay_hash)
	})
	if replay_file then
		local score = Scores:find({file_id = replay_file.id})
		util.redirect_to(self, self:url_for(score))
		return {status = 201, json = {id = score.id}}
	end

	replay_file = Files:create({
		hash = Filehash:for_db(params.replay_hash),
		name = "replay",
		format = Formats:for_db("undefined"),
		storage = Storages:for_db("replays"),
		uploaded = false,
		size = 0,
		loaded = false,
		created_at = created_at,
	})
	if Files:exists(replay_file) then
		replay_file.uploaded = true
		replay_file:update("uploaded")
	end

	local score = Scores:create({
		user_id = self.session.user_id,
		notechart_id = notechart.id,
		modifierset_id = 0,
		file_id = replay_file.id,
		inputmode = Inputmodes:for_db("undefined"),
		is_complete = false,
		is_valid = false,
		is_ranked = false,
		is_top = false,
		created_at = created_at,
		score = 0,
		accuracy = 0,
		max_combo = 0,
		misses_count = 0,
		difficulty = 0,
		rating = 0,
	})

	notechart.scores_count = notechart.scores_count + 1
	notechart:update("scores_count")

	util.redirect_to(self, self:url_for(score))
	return {status = 201, json = {id = score.id}}
end

scores_c.context.PATCH = {"request_session", "session_user", "user_roles"}
scores_c.policies.PATCH = {
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
scores_c.validations.PATCH = {
	{"per_page", type = "number", is_integer = true, default = 10, range = {0}, optional = true},
	require("validations.page_num"),
	{"force", type = "boolean", optional = true},
}
scores_c.PATCH = function(self)
	local score_c = require("controllers.score")
	local params = self.params

	local jq = Joined_query:new(Scores.db)
	jq:select("s")
	if not params.force then
		jq:where("s.is_complete = ?", false)
	end
	jq:orders("s.id asc")
	jq:fields("s.*")

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local query, options = jq:concat()
	options.per_page = per_page or 10

	local paginator = Scores:paginated(query, options)
	local scores = paginator:get_page(page_num)

	local complete_count = 0
	local incomplete_count = 0
	local incomplete_ids = {}
	for _, score in ipairs(scores) do
		local is_valid = score.is_valid
		local success, code, message = score_c.process_score(score)
		score_c.update_stats(score, is_valid)
		if not success then
			incomplete_count = incomplete_count + 1
			table.insert(incomplete_ids, score.id)
		else
			complete_count = complete_count + 1
		end
	end

	return {status = 200, json = {
		complete_count = complete_count,
		incomplete_count = incomplete_count,
		incomplete_ids = incomplete_ids,
	}}
end

scores_c.context.PUT = {"request_session", "session_user", "user_roles"}
scores_c.policies.PUT = {
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
scores_c.validations.PUT = {
	{"per_page", type = "number", is_integer = true, default = 10, range = {0}, optional = true},
	require("validations.page_num"),
	{"force", type = "boolean", optional = true},
}
scores_c.PUT = function(self)
	local score_leaderboards_c = require("controllers.score.leaderboards")
	local params = self.params

	local jq = Joined_query:new(Scores.db)
	jq:select("s")
	jq:where("s.is_complete = ?", true)
	jq:where("s.is_valid = ?", true)
	if not params.force then
		jq:where("s.is_ranked = ?", false)
	end
	jq:orders("s.id asc")
	jq:fields("s.*")

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local query, options = jq:concat()
	options.per_page = per_page or 10

	local paginator = Scores:paginated(query, options)
	local scores = paginator:get_page(page_num)

	local complete_count = 0
	local incomplete_count = 0
	local incomplete_ids = {}
	for _, score in ipairs(scores) do
		local count = score_leaderboards_c.update_leaderboards(score)
		if count == 0 then
			incomplete_count = incomplete_count + 1
			table.insert(incomplete_ids, score.id)
		else
			complete_count = complete_count + 1
		end
	end

	return {status = 200, json = {
		complete_count = complete_count,
		incomplete_count = incomplete_count,
		incomplete_ids = incomplete_ids,
	}}
end

return scores_c
