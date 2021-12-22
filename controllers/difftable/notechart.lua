local Difftable_notecharts = require("models.difftable_notecharts")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local difftable_notechart_c = Controller:new()

difftable_notechart_c.path = "/difftables/:difftable_id[%d]/notecharts/:notechart_id[%d]"
difftable_notechart_c.methods = {"PUT", "DELETE", "PATCH"}

difftable_notechart_c.policies.PUT = {{"permit"}}
difftable_notechart_c.validations.PUT = {
	{"difficulty", type = "number", optional = true},
}
difftable_notechart_c.PUT = function(request)
	local params = request.params

    local new_difftable_notechart = {
        difftable_id = params.difftable_id,
        notechart_id = params.notechart_id,
    }
	local difftable_notechart = Difftable_notecharts:find(new_difftable_notechart)
    if not difftable_notechart then
		new_difftable_notechart.difficulty = params.difficulty or 0
        difftable_notechart = Difftable_notecharts:create(new_difftable_notechart)
    end

	return 200, {difftable_notechart = difftable_notechart}
end

difftable_notechart_c.policies.DELETE = {{"permit"}}
difftable_notechart_c.DELETE = function(request)
	local params = request.params

    local difftable_notechart = Difftable_notecharts:find({
        difftable_id = params.difftable_id,
        notechart_id = params.notechart_id,
    })
    if difftable_notechart then
        difftable_notechart:delete()
    end

	return 200, {}
end

difftable_notechart_c.policies.PATCH = {{"permit"}}
difftable_notechart_c.validations.PATCH = {
	{"difficulty", type = "number", optional = true},
}
difftable_notechart_c.PATCH = function(request)
	local params = request.params

	local difftable_notechart = Difftable_notecharts:find({
        difftable_id = params.difftable_id,
        notechart_id = params.notechart_id,
    })
    if not difftable_notechart then
		return 200, {}
    end
	difftable_notechart.difficulty = params.difficulty
	difftable_notechart:update("difficulty")

	return 200, {difftable_notechart = difftable_notechart}
end

return difftable_notechart_c
