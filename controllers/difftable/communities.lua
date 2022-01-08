local Community_difftables = require("models.community_difftables")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload
local util = require("util")

local difftable_communities_c = Controller:new()

difftable_communities_c.path = "/difftables/:difftable_id[%d]/communities"
difftable_communities_c.methods = {"GET"}

difftable_communities_c.context.GET = {"difftable"}
difftable_communities_c.policies.GET = {{"permit"}}
difftable_communities_c.validations.GET = util.add_belongs_to_validations(Community_difftables.relations)
difftable_communities_c.GET = function(self)
	local params = self.params
	local community_difftables = Community_difftables:find_all({params.difftable_id}, "difftable_id")

	if params.no_data then
		return {json = {
			total = #community_difftables,
			filtered = #community_difftables,
		}}
	end

	preload(community_difftables, util.get_relatives_preload(Community_difftables, params))
	util.recursive_to_name(community_difftables)

	return {json = {
		total = #community_difftables,
		filtered = #community_difftables,
		community_difftables = community_difftables,
	}}
end

return difftable_communities_c
