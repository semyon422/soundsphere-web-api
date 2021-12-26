local Files = require("models.files")

return function(self)
	if self.context.file then return true end
	local file_id = self.params.file_id
	if file_id then
		self.context.file = Files:find(file_id)
	end
	return self.context.file
end
