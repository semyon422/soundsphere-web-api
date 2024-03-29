local Files = require("models.files")
local Controller = require("Controller")
local Formats = require("enums.formats")
local Filehash = require("util.filehash")
local util = require("util")

local file_c = Controller:new()

file_c.path = "/files/:file_id[%d]"
file_c.methods = {"GET", "PUT", "DELETE"}

file_c.context.GET = {"file", "request_session", "session_user", "user_roles"}
file_c.policies.GET = {
	{"authed"},
}
file_c.validations.GET = {
	{"download", type = "boolean", optional = true},
}
util.add_belongs_to_validations(Files.relations, file_c.validations.GET)
file_c.GET = function(self)
	local file = self.context.file:to_name()

	local params = self.params
	if not params.download then
		util.get_relatives(file, params, true)
		return {json = {file = file}}
	end

	local donator = file_c:check_policies(self, "donator_policies")
	if not donator and file.storage ~= "replays" then
		return {status = 403}
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

file_c.context.DELETE = {"file", "request_session", "session_user", "user_roles"}
file_c.policies.DELETE = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
file_c.DELETE = function(self)
	self.context.file:delete()
	return {status = 204}
end

file_c.context.PUT = {"file", "request_session", "session_user", "user_roles"}
file_c.policies.PUT = {
	{"authed", {not_params = "force"}},
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
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

	local hash = Filehash:sum_for_db(params.file.content)
	if hash ~= file.hash then
		return {status = 400, json = {message = "Wrong file hash"}}
	end

	file.hash = hash
	file.name = params.file.filename
	file.format = Formats:get_format_for_db(params.file.filename)
	file.uploaded = true
	file.size = #params.file.content
	file:update("hash", "name", "format", "uploaded", "size")

	Files:write_file(file, params.file.content)

	file:to_name()
	local user = self.context.session_user
	if file.storage == "notecharts" then
		user.notecharts_upload_size = user.notecharts_upload_size + file.size
		user:update("notecharts_upload_size")
	elseif file.storage == "replays" then
		user.replays_upload_size = user.replays_upload_size + file.size
		user:update("replays_upload_size")
	end

	return {json = {file = file}}
end

return file_c
