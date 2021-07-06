local Table_notecharts = require("models.table_notecharts")

local notechartss_c = {}

notechartss_c.GET = function(params)
	local table_notecharts = Table_notecharts:find_all({params.table_id}, "table_id")

	local count = Table_notecharts:count()

	return 200, {
		total = count,
		filtered = count,
		notecharts = table_notecharts
	}
end

return notechartss_c
