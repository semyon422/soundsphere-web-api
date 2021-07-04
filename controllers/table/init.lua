local tables = require("models.tables")

local table_c = {}

table_c.GET = function(params)
	local db_table_entry = tables:find(params.table_id)

	if db_table_entry then
		return 200, {table = db_table_entry}
	end

	return 404, {error = "Not found"}
end

return table_c
