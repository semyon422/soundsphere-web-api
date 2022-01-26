local Notecharts = require("models.notecharts")
local difftable_notechart_c = require("controllers.difftable.notechart")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
local Inputmodes = require("enums.inputmodes")
local Filehash = require("util.filehash")
local Controller = require("Controller")
local Files = require("models.files")
local Ranked_caches = require("models.ranked_caches")
local Ranked_cache_difftables = require("models.ranked_cache_difftables")
local util = require("util")
local preload = require("lapis.db.model").preload
local config = require("lapis.config").get()

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

notecharts_c.default_difftable_ids = {
	osu = 1,
	quaver = 2,
}

notecharts_c.check_notechart = function(self, hash, format, trusted)
	if not config.is_ranked_check_enabled then
		return true
	end

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
			if current_ranked_cache.id ~= ranked_cache.id then
				current_ranked_cache:delete()
			end
		end
		ranked_cache.is_complete = true
		ranked_cache:update("is_complete")
	end

	local difftable_id = notecharts_c.default_difftable_ids[format]
	if difftable_id and not trusted then
		if not ranked_cache then
			ranked_cache = Ranked_caches:create({
				hash = hash_for_db,
				format = format_for_db,
				exists = true,
				ranked = true,
				created_at = created_at,
				expires_at = created_at,
				user_id = self.session.user_id,
			})
		end
		Ranked_cache_difftables:create({
			ranked_cache_id = ranked_cache.id,
			difftable_id = difftable_id,
			index = 0,
			difficulty = 0,
		})
	end

	return true
end

notecharts_c.process_ranked_cache = function(file)
	local ranked_cache = Ranked_caches:find({hash = file.hash})
	if not ranked_cache then
		return
	end

	local notecharts = file:get_notecharts()
	local notechart_by_index = {}
	for _, notechart in ipairs(notecharts) do
		notechart_by_index[notechart.index] = notechart
	end

	local ranked_cache_difftables = ranked_cache:get_ranked_cache_difftables()
	local count = #ranked_cache_difftables
	for _, ranked_cache_difftable in ipairs(ranked_cache_difftables) do
		local index = ranked_cache_difftable.index
		if index == 0 then
			for _, notechart in ipairs(notecharts) do
				difftable_notechart_c.add_difftable_notechart(
					ranked_cache_difftable.difftable_id,
					notechart,
					ranked_cache_difftable.difficulty
				)
			end
			ranked_cache_difftable:delete()
			count = count - 1
		else
			local notechart = notechart_by_index[index]
			if notechart then
				difftable_notechart_c.add_difftable_notechart(
					ranked_cache_difftable.difftable_id,
					notechart,
					ranked_cache_difftable.difficulty
				)
				ranked_cache_difftable:delete()
				count = count - 1
			end
		end
	end
	if count == 0 then
		ranked_cache:delete()
	end
end

notecharts_c.context.POST = {"request_session", "session_user", "user_roles"}
notecharts_c.policies.POST = {
	-- {"authed", {not_params = "trusted"}},
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
			is_complete = false,
			is_valid = false,
			scores_count = 0,
			inputmode = Inputmodes:for_db("undefined"),
			difficulty = 0,
			song_title = "",
			song_artist = "",
			difficulty_name = "",
			difficulty_creator = "",
			level = 0,
			length = 0,
			notes_count = 0,
		})
	end

	return {status = 201, redirect_to = self:url_for(notechart)}
end

return notecharts_c
