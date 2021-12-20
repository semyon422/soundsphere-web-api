local Notecharts = require("models.notecharts")
local Controller = require("Controller")

local notechart_c = Controller:new()

notechart_c.path = "/notecharts/:notechart_id[%d]"
notechart_c.methods = {"GET"}

notechart_c.policies.GET = {{"permit"}}
notechart_c.GET = function(request)
	local params = request.params
	local notechart = Notecharts:find(params.notechart_id)

	return 200, {notechart = notechart}
end

return notechart_c
