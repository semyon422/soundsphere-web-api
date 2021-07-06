local Notecharts = require("models.notecharts")

local notechart_c = {}

notechart_c.GET = function(params)
	local notechart = Notecharts:find(params.notechart_id)

	if notechart then
		return 200, {notechart = notechart}
	end

	return 404, {error = "Not found"}
end

return notechart_c
