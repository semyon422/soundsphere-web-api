local Difftables = require("models.difftables")
local Controller = require("Controller")
local util = require("util")

local additions = {
	difftable_communities = require("controllers.difftable.communities"),
	difftable_leaderboards = require("controllers.difftable.leaderboards"),
	difftable_notecharts = require("controllers.difftable.notecharts"),
	difftable_inputmodes = require("controllers.difftable.inputmodes"),
}

local difftable_c = Controller:new()

difftable_c.path = "/difftables/:difftable_id[%d]"
difftable_c.methods = {"GET", "PATCH", "DELETE"}

difftable_c.context.GET = {"difftable"}
difftable_c.policies.GET = {{"context_loaded"}}
difftable_c.validations.GET = {}
util.add_additions_validations(additions, difftable_c.validations.GET)
util.add_belongs_to_validations(Difftables.relations, difftable_c.validations.GET)
difftable_c.GET = function(self)
	local params = self.params
	local difftable = self.context.difftable

	util.get_relatives(difftable, self.params, true)
	util.load_additions(self, difftable, params, additions)

	return {json = {difftable = difftable}}
end

difftable_c.policies.PATCH = {{"permit"}}
difftable_c.PATCH = function(self)
	return {}
end

difftable_c.policies.DELETE = {{"permit"}}
difftable_c.DELETE = function(self)
	return {status = 204}
end

return difftable_c
