local Notecharts = require("models.notecharts")

local notechart_c = {}

notechart_c.GET = function(params)
	local notechart = Notecharts:find(params.notechart_id)

	return 200, {notechart = notechart}
end

return notechart_c