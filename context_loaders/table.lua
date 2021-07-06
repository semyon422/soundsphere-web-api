local Tables = require("models.tables")

local context_loader = {}

function context_loader:load_context(context)
	if context.table then return print("context.table") end
	local table_id = context.req.params.table_id
	if table_id then
		context.table = Tables:find(table_id)
	end
end

return context_loader
