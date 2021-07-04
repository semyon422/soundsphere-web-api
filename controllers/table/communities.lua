local community_tables = require("models.community_tables")

local communities_c = {}

communities_c.GET = function(params)
	local db_community_entries = community_tables:find_all({params.table_id}, "table_id")

	local count = community_tables:count()

	return 200, {
		total = count,
		filtered = count,
		communities = db_community_entries
	}
end

return communities_c
