local Difftable_notecharts = require("models.difftable_notecharts")
local preload = require("lapis.db.model").preload
local util = require("util")
local Controller = require("Controller")

local difftable_notecharts_c = Controller:new()

difftable_notecharts_c.path = "/difftables/:difftable_id[%d]/notecharts"
difftable_notecharts_c.methods = {"GET"}

difftable_notecharts_c.policies.GET = {{"permit"}}
difftable_notecharts_c.validations.GET = {
	require("validations.no_data"),
}
util.add_belongs_to_validations(Difftable_notecharts.relations, difftable_notecharts_c.validations.GET)
difftable_notecharts_c.GET = function(self)
	local params = self.params

	local difftable_notecharts = Difftable_notecharts:find_all({params.difftable_id}, "difftable_id")

	if params.no_data then
		return {json = {
			total = #difftable_notecharts,
			filtered = #difftable_notecharts,
		}}
	end

	preload(difftable_notecharts, util.get_relatives_preload(Difftable_notecharts, params))
	util.recursive_to_name(difftable_notecharts)

	return {json = {
		total = #difftable_notecharts,
		filtered = #difftable_notecharts,
		difftable_notecharts = difftable_notecharts,
	}}
end

return difftable_notecharts_c
