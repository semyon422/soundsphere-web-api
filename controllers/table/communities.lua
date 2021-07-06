local Community_tables = require("models.community_tables")

local communities_c = {}

communities_c.GET = function(params)
	local community_tables = Community_tables:find_all({params.table_id}, "table_id")

	local count = Community_tables:count()

	return 200, {
		total = count,
		filtered = count,
		communities = community_tables
	}
end

return communities_c
