local Difftable_notecharts = require("models.difftable_notecharts")
local Difftables = require("models.difftables")
local preload = require("lapis.db.model").preload
local util = require("util")
local Controller = require("Controller")

local notechart_difftables_c = Controller:new()

notechart_difftables_c.path = "/notecharts/:notechart_id[%d]/difftables"
notechart_difftables_c.methods = {"GET"}

notechart_difftables_c.policies.GET = {{"permit"}}
notechart_difftables_c.validations.GET = {}
util.add_belongs_to_validations(Difftable_notecharts.relations, notechart_difftables_c.validations.GET)
util.add_has_many_validations(Difftables.relations, notechart_difftables_c.validations.GET)
notechart_difftables_c.GET = function(self)
	local params = self.params

	local difftable_notecharts = Difftable_notecharts:find_all({params.notechart_id}, "notechart_id")

	if params.no_data then
		return {json = {
			total = #difftable_notecharts,
			filtered = #difftable_notecharts,
		}}
	end

	preload(difftable_notecharts, util.get_relatives_preload(Difftable_notecharts, params))
	util.relatives_preload_field(difftable_notecharts, "difftable", Difftables, params)
	util.recursive_to_name(difftable_notecharts)

	return {json = {
		total = #difftable_notecharts,
		filtered = #difftable_notecharts,
		difftable_notecharts = difftable_notecharts,
	}}
end

return notechart_difftables_c
