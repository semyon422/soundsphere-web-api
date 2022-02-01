local Files = require("models.files")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
local Filehash = require("util.filehash")
local Controller = require("Controller")
local util = require("util")
local preload = require("lapis.db.model").preload

local files_c = Controller:new()

files_c.path = "/files"
files_c.methods = {"GET", "POST"}

files_c.policies.GET = {{"permit"}}
files_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
}
util.add_belongs_to_validations(Files.relations, files_c.validations.GET)
util.add_has_many_validations(Files.relations, files_c.validations.GET)
files_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local paginator = Files:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local files = paginator:get_page(page_num)
	preload(files, util.get_relatives_preload(Files, params))
	util.recursive_to_name(files)

	local count = tonumber(Files:count())

	return {json = {
		total = count,
		filtered = count,
		files = files,
	}}
end

files_c.context.POST = {"request_session", "session_user", "user_roles"}
files_c.policies.POST = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
files_c.validations.POST = {
	{"storage", exists = true, type = "string", one_of = Storages.list, default = Storages.list[1]},
	{"file", is_file = true, param_type = "body", optional = true},
	{"hash", exists = true, type = "string", param_type = "body", optional = true},
	{"size", exists = true, type = "number", param_type = "body", optional = true},
}
files_c.POST = function(self)
	local params = self.params

	local hash = params.hash and Filehash:sum_for_db(params.hash)
	local size = params.size
	if params.file then
		hash = Filehash:sum_for_db(params.file.content)
		size = #params.file.content
	end

	if not hash or not size then
		return {status = 200, json = {message = "Missing file or hash and size"}}
	end

	local file = Files:find({hash = hash})
	if file then
		util.redirect_to(self, self:url_for(file))
		return {status = 200, json = {id = file.id}}
	end

	file = Files:create({
		hash = hash,
		name = params.file.filename,
		format = Formats:get_format_for_db(params.file.filename),
		storage = Storages:for_db(params.storage),
		uploaded = params.file ~= nil,
		size = size,
		loaded = false,
		created_at = os.time(),
	})
	if not Files:exists(file) then
		Files:write_file(file, params.file.content)
	end

	util.redirect_to(self, self:url_for(file))
	return {status = 201, json = {id = file.id}}
end

return files_c
