local Difftable_inputmodes = require("models.difftable_inputmodes")
local Controller = require("Controller")
local util = require("util")
local preload = require("lapis.db.model").preload

local difftable_inputmodes_c = Controller:new()

difftable_inputmodes_c.path = "/difftables/:difftable_id[%d]/inputmodes"
difftable_inputmodes_c.methods = {"GET"}

difftable_inputmodes_c.policies.GET = {{"permit"}}
difftable_inputmodes_c.validations.GET = {
	require("validations.no_data"),
}
util.add_belongs_to_validations(Difftable_inputmodes.relations, difftable_inputmodes_c.validations.GET)
difftable_inputmodes_c.GET = function(self)
	local params = self.params
	local difftable_inputmodes = Difftable_inputmodes:find_all({params.difftable_id}, "difftable_id")

	if params.no_data then
		return {json = {
			total = #difftable_inputmodes,
			filtered = #difftable_inputmodes,
		}}
	end

	preload(difftable_inputmodes, util.get_relatives_preload(Difftable_inputmodes, params))
	util.recursive_to_name(difftable_inputmodes)

	return {json = {
		total = #difftable_inputmodes,
		filtered = #difftable_inputmodes,
		difftable_inputmodes = difftable_inputmodes,
	}}
end

return difftable_inputmodes_c
