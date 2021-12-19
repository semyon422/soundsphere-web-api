local Difftables = require("models.difftables")
local Difftable_notecharts = require("models.difftable_notecharts")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")

local difftable_c = Controller:new()

difftable_c.path = "/difftables/:difftable_id[%d]"
difftable_c.methods = {"GET", "PATCH", "DELETE"}
difftable_c.context = {}
difftable_c.policies = {
	GET = require("policies.public"),
}

difftable_c.GET = function(request)
	local params = request.params
	local difftable = Difftables:find(params.difftable_id)

	if not difftable then
		return 200, {}
	end

	local clause = Difftables.db.encode_clause({difftable_id = difftable.id})
	local notecharts_count = Difftable_notecharts:count(clause)
	if difftable.notecharts_count ~= notecharts_count then
		difftable.notecharts_count = notecharts_count
		difftable:update("notecharts_count")
	end

	difftable.inputmodes = Inputmodes:entries_to_list(difftable:get_difftable_inputmodes())
	difftable.difftable_inputmodes = nil

	return 200, {difftable = difftable}
end

difftable_c.PATCH = function(request)
	return 200, {}
end

difftable_c.DELETE = function(request)
	return 200, {}
end

return difftable_c
