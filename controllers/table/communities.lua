local Community_tables = require("models.community_tables")
local preload = require("lapis.db.model").preload

local communities_c = {}

communities_c.GET = function(params)
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

return communities_c
