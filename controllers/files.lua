local Files = require("models.files")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
local Filehash = require("util.filehash")
local Controller = require("Controller")

local files_c = Controller:new()

files_c.path = "/files"
files_c.methods = {"GET", "POST"}

files_c.policies.GET = {{"permit"}}
files_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
}
files_c.GET = function(request)
	local params = request.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local paginator = Files:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local files = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	for _, file in ipairs(files) do
		file:to_name()
	end

	local count = tonumber(Files:count())

	return {json = {
		total = count,
		filtered = count,
		files = files,
	}}
end

files_c.context.POST = {"request_session"}
files_c.policies.POST = {{"authenticated"}}
files_c.validations.POST = {
	{"storage", exists = true, type = "string", one_of = Storages.list, default = Storages.list[1]},
	{"file", is_file = true, param_type = "body"},
}
files_c.POST = function(request)
	local params = request.params

	local hash = Filehash:sum_for_db(params.file.content)

	local file = Files:find({
		hash = hash
	})
	if file then
		return {
			status = 200,
			redirect_to = request:url_for(file),
		}
	end

	file = Files:create({
		hash = hash,
		name = params.file.filename,
		format = Formats:get_format_for_db(params.file.filename),
		storage = Storages:for_db(params.storage),
		uploaded = true,
		size = #params.file.content,
		loaded = false,
		created_at = os.time(),
	})

	return {status = 201, redirect_to = request:url_for(file)}
end

return files_c
