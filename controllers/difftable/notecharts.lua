local Difftable_notecharts = require("models.difftable_notecharts")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local difftable_notecharts_c = Controller:new()

difftable_notecharts_c.path = "/difftables/:difftable_id[%d]/notecharts"
difftable_notecharts_c.methods = {"GET"}

difftable_notecharts_c.context.GET = {"difftable"}
difftable_notecharts_c.policies.GET = {{"permit"}}
difftable_notecharts_c.GET = function(request)
	local params = request.params

	local difftable_notecharts = Difftable_notecharts:find_all({params.difftable_id}, "difftable_id")

	if params.no_data then
		return 200, {
			total = #difftable_notecharts,
			filtered = #difftable_notecharts,
		}
	end

	preload(difftable_notecharts, "notechart")

	local notecharts = {}
	for _, difftable_notechart in ipairs(difftable_notecharts) do
		table.insert(notecharts, difftable_notechart.notechart:to_name())
	end

	return 200, {
		total = #notecharts,
		filtered = #notecharts,
		notecharts = notecharts,
	}
end

return difftable_notecharts_c
