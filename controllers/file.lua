local Files = require("models.files")
local Controller = require("Controller")
local Formats = require("enums.formats")
local Storages = require("enums.storages")
local Filehash = require("util.filehash")

local file_c = Controller:new()

file_c.path = "/files/:file_id[%d]"
file_c.methods = {"GET", "PUT", "DELETE"}

file_c.context.GET = {"file"}
file_c.policies.GET = {{"context_loaded"}}
file_c.GET = function(request)
	return 200, {file = request.context.file:to_name()}
end

file_c.context.DELETE = {"file"}
file_c.policies.DELETE = {{"context_loaded"}}
file_c.DELETE = function(request)
	return 200, {}
end

file_c.context.PUT = {"file"}
file_c.policies.PUT = {{"context_loaded"}}
file_c.validations.PUT = {
	{"file", is_file = true, param_type = "body"},
}
file_c.PUT = function(request)
	local params = request.params

	local file = request.context.file

	if file.uploaded then
		return 200, {}
	end

	file.hash = Filehash:sum_for_db(params.file.content)
	file.name = params.file.filename
	file.format = Formats:get_format_for_db(params.file.filename)
	file.uploaded = true
	file.size = #params.file.content
	file:update("hash", "name", "format", "uploaded", "size")

	return 200, {file = file:to_name()}
end

return file_c
