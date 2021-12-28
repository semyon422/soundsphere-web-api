local Difftable_notecharts = require("models.difftable_notecharts")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local difftable_notechart_c = Controller:new()

difftable_notechart_c.path = "/difftables/:difftable_id[%d]/notecharts/:notechart_id[%d]"
difftable_notechart_c.methods = {"PUT", "DELETE"}

difftable_notechart_c.context.PUT = {"difftable_notechart", "request_session"}
difftable_notechart_c.policies.PUT = {{"authenticated"}}
difftable_notechart_c.validations.PUT = {
	{"difficulty", type = "number", optional = true},
}
difftable_notechart_c.PUT = function(request)
	local params = request.params

	local difftable_notechart = request.context.difftable_notechart
	if difftable_notechart then
		difftable_notechart.difficulty = params.difficulty
		difftable_notechart:update("difficulty")
		return 200, {difftable_notechart = difftable_notechart}
	end

	difftable_notechart = Difftable_notecharts:create({
		difftable_id = params.difftable_id,
		notechart_id = params.notechart_id,
		difficulty = params.difficulty or 0,
	})

	return 200, {difftable_notechart = difftable_notechart}
end

difftable_notechart_c.context.DELETE = {"difftable_notechart", "request_session"}
difftable_notechart_c.policies.DELETE = {{"authenticated", "context_loaded"}}
difftable_notechart_c.DELETE = function(request)
    local difftable_notechart = Dequest.context.difftable_notechart
    difftable_notechart:delete()

	return 200, {difftable_notechart = difftable_notechart}
end

return difftable_notechart_c
