local Ranked_cache_difftables = require("models.ranked_cache_difftables")
local preload = require("lapis.db.model").preload
local util = require("util")
local Controller = require("Controller")

local ranked_cache_difftables_c = Controller:new()

ranked_cache_difftables_c.path = "/ranked_caches/:ranked_cache_id[%d]/difftables"
ranked_cache_difftables_c.methods = {"GET"}

ranked_cache_difftables_c.policies.GET = {{"permit"}}
ranked_cache_difftables_c.validations.GET = {
	require("validations.no_data"),
}
util.add_belongs_to_validations(Ranked_cache_difftables.relations, ranked_cache_difftables_c.validations.GET)
ranked_cache_difftables_c.GET = function(self)
	local params = self.params

	local ranked_cache_difftables = Ranked_cache_difftables:find_all({params.ranked_cache_id}, "ranked_cache_id")

	if params.no_data then
		return {json = {
			total = #ranked_cache_difftables,
			filtered = #ranked_cache_difftables,
		}}
	end

	preload(ranked_cache_difftables, util.get_relatives_preload(Ranked_cache_difftables, params))
	util.recursive_to_name(ranked_cache_difftables)

	return {json = {
		total = #ranked_cache_difftables,
		filtered = #ranked_cache_difftables,
		ranked_cache_difftables = ranked_cache_difftables,
	}}
end

return ranked_cache_difftables_c
