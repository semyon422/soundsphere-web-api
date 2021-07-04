local table_notecharts = require("models.table_notecharts")

local notechartss_c = {}

notechartss_c.GET = function(params)
	local db_notecharts_entries = table_notecharts:find_all({params.table_id}, "table_id")

	return 200, {notechartss = db_notecharts_entries}
end

return notechartss_c
