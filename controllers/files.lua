local Files = require("models.files")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
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
		file.format = Formats:to_name(file.format)
		file.storage = Formats:to_name(file.storage)
	end

	local count = Files:count()

	return 200, {
		total = count,
		filtered = count,
		files = files
	}
end

files_c.policies.POST = {{"permit"}}
files_c.validations.POST = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
}
files_c.POST = function(request)
	return 200, {}
end

return files_c
