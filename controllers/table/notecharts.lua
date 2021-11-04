local Table_notecharts = require("models.table_notecharts")
local preload = require("lapis.db.model").preload

local notecharts_c = {}

notecharts_c.GET = function(request)
	local params = request.params
	local table_notecharts = Table_notecharts:find_all({params.table_id}, "table_id")
	preload(table_notecharts, "notechart")

	local notecharts = {}
	for _, table_notechart in ipairs(table_notecharts) do
		table.insert(notecharts, table_notechart.notechart)
	end

	local count = Table_notecharts:count()

	return 200, {
		total = count,
		filtered = count,
		notecharts = notecharts
	}
end

return notecharts_c
