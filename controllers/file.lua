local Files = require("models.files")
local Controller = require("Controller")

local file_c = Controller:new()

file_c.path = "/files/:file_id[%d]"
file_c.methods = {"GET", "PUT", "DELETE"}

file_c.context.GET = {"file"}
file_c.policies.GET = {{"permit"}}
file_c.GET = function(request)
	return 200, {file = request.context.file}
end

file_c.policies.DELETE = {{"permit"}}
file_c.DELETE = function(request)
	return 200, {}
end

file_c.policies.PUT = {{"permit"}}
file_c.validations.PUT = {
	{"file", exists = true, is_file = true},
}
file_c.PUT = function(request)
	return 200, {file = file}
end

return file_c
