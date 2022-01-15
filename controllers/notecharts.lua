local Notecharts = require("models.notecharts")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
local Inputmodes = require("enums.inputmodes")
local Filehash = require("util.filehash")
local Controller = require("Controller")
local Files = require("models.files")
local util = require("util")
local preload = require("lapis.db.model").preload

local notecharts_c = Controller:new()

notecharts_c.path = "/notecharts"
notecharts_c.methods = {"GET", "POST"}

notecharts_c.policies.GET = {{"permit"}}
notecharts_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
}
util.add_belongs_to_validations(Notecharts.relations, notecharts_c.validations.GET)
util.add_has_many_validations(Notecharts.relations, notecharts_c.validations.GET)
notecharts_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local paginator = Notecharts:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local notecharts = paginator:get_page(page_num)
	preload(notecharts, util.get_relatives_preload(Notecharts, params))
	util.recursive_to_name(notecharts)

	local count = tonumber(Notecharts:count())

	return {json = {
		total = count,
		filtered = count,
		notecharts = notecharts,
	}}
end

notecharts_c.context.POST = {"request_session"}
notecharts_c.policies.POST = {{"authenticated"}}
notecharts_c.validations.POST = {
	{"notechart_hash", exists = true, type = "string", param_type = "body"},
	{"notechart_index", exists = true, type = "number", param_type = "body"},
	{"notechart_filename", exists = true, type = "string", param_type = "body"},
	{"notechart_filesize", exists = true, type = "number", param_type = "body"},
}
notecharts_c.POST = function(self)
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

	return {status = 201, redirect_to = self:url_for(notechart)}
end

return notecharts_c
