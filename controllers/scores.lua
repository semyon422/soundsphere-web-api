local Scores = require("models.scores")
local Containers = require("models.containers")
local Notecharts = require("models.notecharts")
local Controller = require("Controller")
local Formats = require("enums.formats")
local Inputmodes = require("enums.inputmodes")

local scores_c = Controller:new()

scores_c.path = "/scores"
scores_c.methods = {"GET", "POST"}

scores_c.policies.GET = {{"permit"}}
scores_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
}
scores_c.GET = function(request)
	local params = request.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local paginator = Scores:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local scores = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	local count = Scores:count()

	return 200, {
		total = count,
		filtered = count,
		scores = scores
	}
end

scores_c.context.POST = {"session"}
scores_c.policies.POST = {{"authenticated"}}
scores_c.validations.POST = {
	{"replay_hash", exists = true, type = "string", body = true},
	{"replay_size", exists = true, type = "number", body = true},
	{"notechart_hash", exists = true, type = "string", body = true},
	{"notechart_index", exists = true, type = "number", body = true},
	{"notechart_filename", exists = true, type = "string", body = true},
	{"notechart_filesize", exists = true, type = "number", body = true},
}
scores_c.POST = function(request)
	local params = request.params

	local created_at = os.time()

	local container = Containers:find({
		hash = params.notechart_hash
	})
	if not container then
		container = Containers:create({
			hash = params.notechart_hash,
			format = Formats:get_format_for_db(params.notechart_filename),
			uploaded = false,
			size = params.notechart_filesize,
			imported = false,
			created_at = created_at,
		})
	end

	local notechart = Notecharts:find({
		container_id = container.id,
		index = params.notechart_index,
	})
	if not notechart then
		notechart = Notecharts:create({
			container_id = container.id,
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

	local score = Scores:find({
		replay_hash = params.replay_hash,
	})
	if not score then
		score = Scores:create({
			user_id = request.session.user_id,
			notechart_id = notechart.id,
			modifierset_id = 0,
			inputmode = Inputmodes:for_db("undefined"),
			replay_hash = params.replay_hash,
			is_valid = false,
			calculated = false,
			replay_uploaded = false,
			replay_size = params.replay_size,
			created_at = created_at,
			score = 0,
			accuracy = 0,
			max_combo = 0,
			performance = 0,
		})
	end

	return 200, {}
end

return scores_c
