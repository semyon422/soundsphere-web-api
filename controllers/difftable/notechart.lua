local Difftable_notecharts = require("models.difftable_notecharts")
local Difftable_inputmodes = require("models.difftable_inputmodes")
local util = require("util")
local Controller = require("Controller")

local difftable_notechart_c = Controller:new()

difftable_notechart_c.path = "/difftables/:difftable_id[%d]/notecharts/:notechart_id[%d]"
difftable_notechart_c.methods = {"GET", "PUT", "PATCH", "DELETE"}

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
		return {status = 204}
	end

	difftable_notechart = Difftable_notecharts:create({
		difftable_id = params.difftable_id,
		notechart_id = params.notechart_id,
		difficulty = params.difficulty or 0,
	})

	local notechart = difftable_notechart:get_notechart()
	local new_difftable_inputmode = {
		difftable_id = params.difftable_id,
		inputmode = notechart.inputmode,
	}
	local difftable_inputmode = Difftable_inputmodes:find(new_difftable_inputmode)
	if not difftable_inputmode then
		new_difftable_inputmode.notecharts_count = 1
		Difftable_inputmodes:create(new_difftable_inputmode)
	else
		difftable_inputmode.notecharts_count = difftable_inputmode.notecharts_count + 1
		difftable_inputmode:update("notecharts_count")
	end

	local difftable = difftable_notechart:get_difftable()
	difftable.notecharts_count = difftable.notecharts_count + 1
	difftable:update("notecharts_count")

	return {json = {difftable_notechart = difftable_notechart}}
end

difftable_notechart_c.context.PATCH = {"difftable_notechart", "request_session"}
difftable_notechart_c.policies.PATCH = {{"context_loaded", "authenticated"}}
difftable_notechart_c.validations.PATCH = {
	{"difficulty", type = "number", optional = true},
}
difftable_notechart_c.PATCH = function(self)
	local params = self.params

	local difftable_notechart = self.context.difftable_notechart
	difftable_notechart.difficulty = params.difficulty
	difftable_notechart:update("difficulty")

	return {json = {difftable_notechart = difftable_notechart}}
end

difftable_notechart_c.context.DELETE = {"difftable_notechart", "request_session"}
difftable_notechart_c.policies.DELETE = {{"context_loaded", "authenticated"}}
difftable_notechart_c.DELETE = function(self)
	local params = self.params

    local difftable_notechart = self.context.difftable_notechart
    difftable_notechart:delete()

	local notechart = difftable_notechart:get_notechart()
	local difftable_inputmode = Difftable_inputmodes:find({
		difftable_id = params.difftable_id,
		inputmode = notechart.inputmode,
	})
	difftable_inputmode.notecharts_count = math.max(difftable_inputmode.notecharts_count - 1, 0)
	if difftable_inputmode.notecharts_count > 0 then
		difftable_inputmode:update("notecharts_count")
	else
		difftable_inputmode:delete()
	end

	local difftable = difftable_notechart:get_difftable()
	difftable.notecharts_count = math.max(difftable.notecharts_count - 1, 0)
	difftable:update("notecharts_count")

	return {status = 204}
end

return difftable_notechart_c
