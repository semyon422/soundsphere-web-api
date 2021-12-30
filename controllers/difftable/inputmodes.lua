local Difftable_inputmodes = require("models.difftable_inputmodes")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")

local difftable_inputmodes_c = Controller:new()

difftable_inputmodes_c.path = "/difftables/:difftable_id[%d]/inputmodes"
difftable_inputmodes_c.methods = {"GET"}

difftable_inputmodes_c.policies.GET = {{"permit"}}
difftable_inputmodes_c.validations.GET = {
	require("validations.no_data"),
}
difftable_inputmodes_c.GET = function(request)
	local params = request.params
	local difftable_inputmodes = Difftable_inputmodes:find_all({params.difftable_id}, "difftable_id")

	if params.no_data then
		return {json = {
			total = #difftable_inputmodes,
			filtered = #difftable_inputmodes,
		}}
	end

	local inputmodes = Inputmodes:entries_to_list(difftable_inputmodes)

	return {json = {
		total = #inputmodes,
		filtered = #inputmodes,
		inputmodes = inputmodes,
	}}
end

return difftable_inputmodes_c
