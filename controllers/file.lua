local Files = require("models.files")
local Controller = require("Controller")
local Formats = require("enums.formats")
local Filehash = require("util.filehash")
local util = require("util")

local file_c = Controller:new()

file_c.path = "/files/:file_id[%d]"
file_c.methods = {"GET", "PUT", "DELETE"}

file_c.context.GET = {"file"}
file_c.policies.GET = {{"context_loaded"}}
file_c.validations.GET = {
	{"download", type = "boolean", optional = true},
}
util.add_belongs_to_validations(Files.relations, file_c.validations.GET)
file_c.GET = function(self)
	local params = self.params

	local file = self.context.file

	if not params.download then
		util.get_relatives(file, self.params, true)
		return {json = {file = file:to_name()}}
	end

	return {
		Files:read_file(file),
		status = 200,
		content_type = "application/octet-stream",
		headers = {
			["Pragma"] = "public",
			["Cache-Control"] = "must-revalidate, post-check=0, pre-check=0",
			["Content-Disposition"] = 'attachment; filename="' .. file.name .. '"',
			["Content-Transfer-Encoding"] = "binary",
		},
	}
end

file_c.context.DELETE = {"file"}
file_c.policies.DELETE = {{"context_loaded"}}
file_c.DELETE = function(self)
	return {status = 204}
end

file_c.context.PUT = {"file"}
file_c.policies.PUT = {{"context_loaded"}}
file_c.validations.PUT = {
	{"force", type = "boolean", optional = true},
	{"file", is_file = true, param_type = "body"},
}
file_c.PUT = function(self)
	local params = self.params

	local file = self.context.file

	if file.uploaded and not params.force then
		return {status = 204}
	end

	file.hash = Filehash:sum_for_db(params.file.content)
	file.name = params.file.filename
	file.format = Formats:get_format_for_db(params.file.filename)
	file.uploaded = true
	file.size = #params.file.content
	file:update("hash", "name", "format", "uploaded", "size")

	Files:write_file(file, params.file.content)

	return {json = {file = file:to_name()}}
end

return file_c
