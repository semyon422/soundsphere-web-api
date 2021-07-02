local notecharts = require("models.notecharts")

local notechart_c = {}

notechart_c.GET = function(params)
	local db_notechart_entry = notecharts:find(params.notechart_id)

	if db_notechart_entry then
		return 200, {notechart = db_notechart_entry}
	end

	return 404, {error = "Not found"}
end

return notechart_c
