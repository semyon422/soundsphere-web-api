local Notecharts = require("models.notecharts")
local difftable_notechart_c = require("controllers.difftable.notechart")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
local Inputmodes = require("enums.inputmodes")
local Filehash = require("util.filehash")
local Joined_query = require("util.joined_query")
local Controller = require("Controller")
local Files = require("models.files")
local Ranked_caches = require("models.ranked_caches")
local Ranked_cache_difftables = require("models.ranked_cache_difftables")
local util = require("util")
local preload = require("lapis.db.model").preload
local config = require("lapis.config").get()

local notecharts_c = Controller:new()

notecharts_c.path = "/notecharts"
notecharts_c.methods = {"GET", "POST", "PATCH"}

notecharts_c.policies.GET = {{"permit"}}
notecharts_c.validations.GET = {
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
	{"is_not_complete", type = "boolean", optional = true},
	{"is_not_valid", type = "boolean", optional = true},
	{"hash", type = "string", optional = true, nil_if = "", min_length = 32, max_length = 32},
	{"index", type = "number", optional = true, nil_if = ""},
}
util.add_belongs_to_validations(Notecharts.relations, notecharts_c.validations.GET)
util.add_has_many_validations(Notecharts.relations, notecharts_c.validations.GET)
notecharts_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local jq = Joined_query:new(Notecharts.db)
	jq:select("n")
	jq:where("n.is_complete = ?", not params.is_not_complete)
	jq:where("n.is_valid = ?", not params.is_not_valid)
	jq:orders("n.id asc")
	jq:fields("n.*")

	local user_id = self.session.user_id
	if user_id then
		jq:select("left join scores s on n.id = s.notechart_id and s.user_id = ? and s.is_top = ?", user_id, true)
		jq:fields("s.user_id")
	end
	if params.hash then
		jq:select("left join files f on n.file_id = f.id")
		jq:where("f.hash = ?", Filehash:for_db(params.hash))
		if params.index then
			jq:where("n.index = ?", params.index)
		end
	end
	if params.search then
		jq:where(util.db_search(
			Notecharts.db,
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
			total = tonumber(Notecharts:count()),
			filtered = tonumber(util.db_count(Notecharts, query)),
		}}
	end

	local paginator = Notecharts:paginated(query, options)
	local notecharts = paginator:get_page(page_num)

	preload(notecharts, util.get_relatives_preload(Notecharts, params))
	util.recursive_to_name(notecharts)

	for _, notechart in ipairs(notecharts) do
		if notechart.user_id then
			notechart.is_played = true
			notechart.user_id = nil
		else
			notechart.is_played = false
		end
	end

	return {json = {
		total = tonumber(Notecharts:count()),
		filtered = tonumber(util.db_count(Notecharts, query)),
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
				expires_at = 0,
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
				difftable_notechart_c.set_difftable_notechart(
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
				difftable_notechart_c.set_difftable_notechart(
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
	{"authed", "session_user_is_banned_deny"},
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
notecharts_c.validations.POST = {
	{"trusted", type = "boolean", optional = true},
	{"notechart_hash", type = "string", param_type = "body", min_length = 32, max_length = 32},
	{"notechart_index", type = "number", param_type = "body"},
	{"notechart_filename", type = "string", param_type = "body", min_length = 1, max_length = 255},
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
			size = 0,
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

	util.redirect_to(self, self:url_for(notechart))
	return {status = 201, json = {id = notechart.id}}
end

notecharts_c.context.PATCH = {"request_session", "session_user", "user_roles"}
notecharts_c.policies.PATCH = {
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
notecharts_c.validations.PATCH = {
	{"count", type = "number", default = "", optional = true},
}
notecharts_c.PATCH = function(self)
	local notechart_c = require("controllers.notechart")
	local params = self.params

	local jq = Joined_query:new(Notecharts.db)
	jq:select("n")
	jq:where("n.is_complete = ?", false)
	jq:orders("n.id asc")
	jq:fields("n.*")

	local query, options = jq:concat()
	options.per_page = params.count or 10

	local paginator = Notecharts:paginated(query, options)
	local notecharts = paginator:get_page(1)

	local complete_count = 0
	local incomplete_count = 0
	local incomplete_ids = {}
	for _, notechart in ipairs(notecharts) do
		local success, code, message = notechart_c.process_notechart(notechart)
		if not success then
			incomplete_count = incomplete_count + 1
			table.insert(incomplete_ids, notechart.id)
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

return notecharts_c
