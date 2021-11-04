local Tables = require("models.tables")

local context_loader = {}

function context_loader:load_context(request)
	if request.context.table then return print("context.table") end
	local table_id = request.params.table_id
	if table_id then
		request.context.table = Tables:find(table_id)
	end
end

return context_loader
