local Ranked_caches = require("models.ranked_caches")
local Formats = require("enums.formats")
local Filehash = require("util.filehash")
local Controller = require("Controller")
local util = require("util")
local preload = require("lapis.db.model").preload

local ranked_caches_c = Controller:new()

ranked_caches_c.path = "/ranked_caches"
ranked_caches_c.methods = {"GET", "POST"}

ranked_caches_c.policies.GET = {{"permit"}}
ranked_caches_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
}
util.add_belongs_to_validations(Ranked_caches.relations, ranked_caches_c.validations.GET)
util.add_has_many_validations(Ranked_caches.relations, ranked_caches_c.validations.GET)
ranked_caches_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local paginator = Ranked_caches:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local ranked_caches = paginator:get_page(page_num)
	preload(ranked_caches, util.get_relatives_preload(Ranked_caches, params))
	util.recursive_to_name(ranked_caches)

	local count = tonumber(Ranked_caches:count())

	return {json = {
		total = count,
		filtered = count,
		ranked_caches = ranked_caches,
	}}
end

ranked_caches_c.context.POST = {"request_session", "session_user", "user_roles"}
ranked_caches_c.policies.POST = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
ranked_caches_c.validations.POST = {
	{"file", is_file = true, param_type = "body", optional = true},
	{"hash", exists = true, type = "string", param_type = "body", optional = true},
	{"format", exists = true, type = "string", param_type = "body", optional = true, one_of = Formats.list},
}
ranked_caches_c.POST = function(self)
	local params = self.params

	local hash = params.hash and Filehash:sum_for_db(params.hash)
	local format = params.format and Formats:for_db(params.format)
	if params.file then
		hash = Filehash:sum_for_db(params.file.content)
		format = Formats:get_format_for_db(params.file.filename)
	end

	if not hash then
		return {status = 200, json = {message = "Missing file or hash"}}
	end

	local ranked_cache = Ranked_caches:find({hash = hash})
	if ranked_cache then
		return {
			status = 200,
			redirect_to = self:url_for(ranked_cache),
		}
	end

	ranked_cache = Ranked_caches:create({
		hash = hash,
		format = format,
		exists = true,
		ranked = true,
		is_complete = true,
		user_id = self.session.user_id,
		created_at = os.time(),
		expires_at = 0,
	})

	return {status = 201, redirect_to = self:url_for(ranked_cache)}
end

return ranked_caches_c
