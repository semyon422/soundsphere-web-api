local Scores = require("models.scores")
local Files = require("models.files")
local Notecharts = require("models.notecharts")
local Controller = require("Controller")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
local Filehash = require("util.filehash")
local Inputmodes = require("enums.inputmodes")
local util = require("util")
local preload = require("lapis.db.model").preload

local scores_c = Controller:new()

scores_c.path = "/scores"
scores_c.methods = {"GET", "POST"}

scores_c.policies.GET = {{"permit"}}
scores_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
}
util.add_belongs_to_validations(Scores.relations, scores_c.validations.GET)
util.add_has_many_validations(Scores.relations, scores_c.validations.GET)
scores_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local paginator = Scores:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local scores = params.get_all and paginator:get_all() or paginator:get_page(page_num)
	preload(scores, util.get_relatives_preload(Scores, params))
	util.recursive_to_name(scores)

	local count = tonumber(Scores:count())

	return {
		json = {
			total = count,
			filtered = count,
			scores = scores,
		}
	}
end

scores_c.context.POST = {"request_session"}
scores_c.policies.POST = {{"authenticated"}}
scores_c.validations.POST = {
	{"replay_hash", exists = true, type = "string", param_type = "body"},
	{"replay_size", exists = true, type = "number", param_type = "body"},
	{"notechart_hash", exists = true, type = "string", param_type = "body"},
	{"notechart_index", exists = true, type = "number", param_type = "body"},
	{"notechart_filename", exists = true, type = "string", param_type = "body"},
	{"notechart_filesize", exists = true, type = "number", param_type = "body"},
}
scores_c.POST = function(self)
	local params = self.params

	local created_at = os.time()

	local notechart_file = Files:find({
		hash = Filehash:for_db(params.notechart_hash)
	})
	if not notechart_file then
		notechart_file = Files:create({
			hash = Filehash:for_db(params.notechart_hash),
			name = params.notechart_filename,
			format = Formats:get_format_for_db(params.notechart_filename),
			storage = Storages:for_db("notecharts"),
			uploaded = false,
			size = params.notechart_filesize,
			loaded = false,
			created_at = created_at,
		})
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
		return {status = 201, redirect_to = self:url_for(score)}
	end

	replay_file = Files:create({
		hash = Filehash:for_db(params.replay_hash),
		name = "replay",
		format = Formats:for_db("undefined"),
		storage = Storages:for_db("replays"),
		uploaded = false,
		size = params.replay_size,
		loaded = false,
		created_at = created_at,
	})
	local score = Scores:create({
		user_id = self.session.user_id,
		notechart_id = notechart.id,
		modifierset_id = 0,
		file_id = replay_file.id,
		inputmode = Inputmodes:for_db("undefined"),
		is_valid = false,
		is_complete = false,
		created_at = created_at,
		score = 0,
		accuracy = 0,
		max_combo = 0,
		performance = 0,
	})

	return {status = 201, redirect_to = self:url_for(score)}
end

return scores_c
