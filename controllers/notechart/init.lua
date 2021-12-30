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
notechart_c.GET = function(self)
	local notechart = self.context.notechart

	get_relatives(notechart, self.params, true)

	return {json = {notechart = notechart:to_name()}}
end

return notechart_c
