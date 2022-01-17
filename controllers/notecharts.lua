local Notecharts = require("models.notecharts")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
local Inputmodes = require("enums.inputmodes")
local Filehash = require("util.filehash")
local Controller = require("Controller")
local Files = require("models.files")
local Ranked_caches = require("models.ranked_caches")
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

notecharts_c.check_notechart = function(self, hash, format, trusted)
	local created_at = os.time()
	local hash_for_db = Filehash:for_db(hash)
	local format_for_db = Formats:for_db(format)
	local ranked_cache = Ranked_caches:find({hash = hash_for_db, format = format_for_db})
	if not ranked_cache then
		if trusted then
			return true
		end
		local exists, ranked = Ranked_caches:check(hash, format)
		if not ranked then
			local delay = exists and 3600 * 24 or 3600 * 24 * 7
			ranked_cache = Ranked_caches:create({
				hash = hash_for_db,
				format = format_for_db,
				exists = exists,
				ranked = false,
				created_at = created_at,
				expires_at = created_at + delay,
				user_id = self.session.user_id,
			})
			return false, "Untrusted notechart"
		end
	else
		if not trusted and not ranked_cache.ranked then
			if ranked_cache.expires_at > created_at then
				return false, "Untrusted notechart (cached)"
			else
				local exists, ranked = Ranked_caches:check(hash, format)
				if not ranked then
					local delay = exists and 3600 * 24 or 3600 * 24 * 7
					ranked_cache.expires_at = created_at + delay
					ranked_cache.exists = exists
					ranked_cache:update("expires_at", "exists")
					return false, "Untrusted notechart"
				end
			end
		end
		local ranked_caches = Ranked_caches:find_all({hash_for_db}, "hash")
		for _, current_ranked_cache in ipairs(ranked_caches) do
			if current_ranked_cache.format ~= format_for_db then
				local user_id = current_ranked_cache.user_id
				-- ban(user_id)
			end
			current_ranked_cache:delete()
		end
	end
	return true
end

notecharts_c.context.POST = {"request_session", "session_user", "user_roles"}
notecharts_c.policies.POST = {
	{"authed", {not_params = "trusted"}},
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
notecharts_c.validations.POST = {
	{"trusted", type = "boolean", optional = true},
	{"notechart_hash", exists = true, type = "string", param_type = "body"},
	{"notechart_index", exists = true, type = "number", param_type = "body"},
	{"notechart_filename", exists = true, type = "string", param_type = "body"},
	{"notechart_filesize", exists = true, type = "number", param_type = "body"},
}
notecharts_c.POST = function(self)
	local params = self.params

	local created_at = os.time()
	local hash_for_db = Filehash:for_db(params.notechart_hash)
	local format_for_db = Formats:get_format_for_db(params.notechart_filename)
	local format = Formats:to_name(format_for_db)

	local notechart_file = Files:find({hash = hash_for_db})
	if not notechart_file then
		local trusted, message = notecharts_c.check_notechart(
			self,
			params.notechart_hash,
			format,
			params.trusted
		)
		if not trusted then
			return {status = 400, json = {message = message}}
		end

		notechart_file = Files:create({
			hash = hash_for_db,
			name = params.notechart_filename,
			format = format_for_db,
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
