local Difftables = require("models.difftables")
local Difftable_notecharts = require("models.difftable_notecharts")
local Inputmodes = require("enums.inputmodes")
local Controller = require("Controller")

local additions = {
	communities = require("controllers.difftable.communities"),
	leaderboards = require("controllers.difftable.leaderboards"),
	notecharts = require("controllers.difftable.notecharts"),
	inputmodes = require("controllers.difftable.inputmodes"),
}

local difftable_c = Controller:new()

difftable_c.path = "/difftables/:difftable_id[%d]"
difftable_c.methods = {"GET", "PATCH", "DELETE"}

difftable_c.context.GET = {"difftable"}
difftable_c.policies.GET = {{"permit"}}
difftable_c.validations.GET = {
	{"communities", type = "boolean", optional = true},
	{"leaderboards", type = "boolean", optional = true},
	{"notecharts", type = "boolean", optional = true},
	{"inputmodes", type = "boolean", optional = true},
}
difftable_c.GET = function(request)
	local params = request.params
	local difftable = request.context.difftable

	local fields = {}
	for param, controller in pairs(additions) do
		local value = params[param]
		if value ~= nil then
			local param_count = param .. "_count"
			params.no_data = value == false
			local _, response = controller.GET(request)
			difftable[param] = response[param]
			if difftable[param_count] and difftable[param_count] ~= response.total then
				difftable[param_count] = response.total
				table.insert(fields, param_count)
			end
		end
	end
	if #fields > 0 then
		difftable:update(unpack(fields))
	end

	return 200, {difftable = difftable}
end

difftable_c.policies.PATCH = {{"permit"}}
difftable_c.PATCH = function(request)
	return 200, {}
end

difftable_c.policies.DELETE = {{"permit"}}
difftable_c.DELETE = function(request)
	return 200, {}
end

return difftable_c
