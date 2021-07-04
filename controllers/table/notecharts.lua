local table_notecharts = require("models.table_notecharts")

local notechartss_c = {}

notechartss_c.GET = function(params)
	local db_notecharts_entries = table_notecharts:find_all({params.table_id}, "table_id")

	local count = table_notecharts:count()

	return 200, {
		total = count,
		filtered = count,
		notecharts = db_notecharts_entries
	}
end

return notechartss_c
