local Tables = require("models.tables")

local table_c = {}

table_c.GET = function(params)
	local table = Tables:find(params.table_id)

	if table then
		return 200, {table = table}
	end

	return 404, {error = "Not found"}
end

return table_c
