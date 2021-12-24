local Notecharts = require("models.notecharts")
local Controller = require("Controller")

local notechart_c = Controller:new()

notechart_c.path = "/notecharts/:notechart_id[%d]"
notechart_c.methods = {"GET"}

notechart_c.context.GET = {"notechart"}
notechart_c.policies.GET = {{"context_loaded"}}
notechart_c.GET = function(request)
	return 200, {notechart = request.context.notechart}
end

return notechart_c
