local Difftable_notecharts = require("models.difftable_notecharts")
local preload = require("lapis.db.model").preload

local difftable_notechart_c = {}

difftable_notechart_c.path = "/difftables/:difftable_id/notecharts/:notechart_id"
difftable_notechart_c.methods = {"PUT", "DELETE", "PATCH"}
difftable_notechart_c.context = {}
difftable_notechart_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
	PATCH = require("policies.public"),
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