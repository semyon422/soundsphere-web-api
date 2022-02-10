local Files = require("models.files")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("file", function(self)
	local file_id = self.params.file_id
	if file_id then
		return Files:find(file_id)
	end
end)
