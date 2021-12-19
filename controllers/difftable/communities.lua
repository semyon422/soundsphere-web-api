local Community_difftables = require("models.community_difftables")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload

local difftable_communities_c = Controller:new()

difftable_communities_c.path = "/difftables/:difftable_id/communities"
difftable_communities_c.methods = {"GET"}
difftable_communities_c.context = {"difftable"}
difftable_communities_c.policies = {
	GET = require("policies.public"),
}

difftable_communities_c.GET = function(request)
	local params = request.params
	local community_difftables = Community_difftables:find_all({params.difftable_id}, "difftable_id")
	preload(community_difftables, "community")

	local communities = {}
	for _, community_difftable in ipairs(community_difftables) do
		table.insert(communities, community_difftable.community)
	end

	local count = Community_difftables:count()

	return 200, {
		total = count,
		filtered = count,
		communities = communities
	}
end

return difftable_communities_c
