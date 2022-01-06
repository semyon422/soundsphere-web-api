local Difftable_notecharts = require("models.difftable_notecharts")
local util = require("util")
local Controller = require("Controller")

local difftable_notechart_c = Controller:new()

difftable_notechart_c.path = "/difftables/:difftable_id[%d]/notecharts/:notechart_id[%d]"
difftable_notechart_c.methods = {"GET", "PUT", "DELETE"}

difftable_notechart_c.context.GET = {"difftable_notechart"}
difftable_notechart_c.policies.GET = {{"context_loaded"}}
difftable_notechart_c.validations.GET = util.add_belongs_to_validations(Difftable_notecharts.relations)
difftable_notechart_c.GET = function(self)
    local difftable_notechart = self.context.difftable_notechart

	util.get_relatives(difftable_notechart, self.params, true)

	return {json = {difftable_notechart = difftable_notechart}}
end

difftable_notechart_c.context.PUT = {"difftable_notechart", "request_session"}
difftable_notechart_c.policies.PUT = {{"authenticated"}}
difftable_notechart_c.validations.PUT = {
	{"difficulty", type = "number", optional = true},
}
difftable_notechart_c.PUT = function(self)
	local params = self.params

	local difftable_notechart = self.context.difftable_notechart
	if difftable_notechart then
		difftable_notechart.difficulty = params.difficulty
		difftable_notechart:update("difficulty")
		return {json = {difftable_notechart = difftable_notechart}}
	end

	difftable_notechart = Difftable_notecharts:create({
		difftable_id = params.difftable_id,
		notechart_id = params.notechart_id,
		difficulty = params.difficulty or 0,
	})

	return {json = {difftable_notechart = difftable_notechart}}
end

difftable_notechart_c.context.DELETE = {"difftable_notechart", "request_session"}
difftable_notechart_c.policies.DELETE = {{"authenticated", "context_loaded"}}
difftable_notechart_c.DELETE = function(self)
    local difftable_notechart = self.context.difftable_notechart
    difftable_notechart:delete()

	return {status = 204}
end

return difftable_notechart_c
