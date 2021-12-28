local Notecharts = require("models.notecharts")
local Controller = require("Controller")
local add_belongs_to_validations = require("util.add_belongs_to_validations")
local get_relatives = require("util.get_relatives")

local notechart_c = Controller:new()

notechart_c.path = "/notecharts/:notechart_id[%d]"
notechart_c.methods = {"GET"}

notechart_c.context.GET = {"notechart"}
notechart_c.policies.GET = {{"context_loaded"}}
notechart_c.validations.GET = add_belongs_to_validations(Notecharts.relations)
notechart_c.GET = function(request)
	local notechart = request.context.notechart

	get_relatives(notechart, request.params, true)

	return 200, {notechart = notechart:to_name()}
end

return notechart_c
