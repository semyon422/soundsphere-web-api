local Community_tables = require("models.community_tables")
local preload = require("lapis.db.model").preload

local table_communities_c = {}

table_communities_c.path = "/tables/:table_id/communities"
table_communities_c.methods = {"GET"}
table_communities_c.context = {"table"}
table_communities_c.policies = {
	GET = require("policies.public"),
}

table_communities_c.GET = function(request)
	local params = request.params
	local community_tables = Community_tables:find_all({params.table_id}, "table_id")
	preload(community_tables, "communities")

	local communities = {}
	for _, community_table in ipairs(community_tables) do
		table.insert(communities, community_table.community)
	end

	local count = Community_tables:count()

	return 200, {
		total = count,
		filtered = count,
		communities = communities
	}
end

return table_communities_c
