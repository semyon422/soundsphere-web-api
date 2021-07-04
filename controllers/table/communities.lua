local community_tables = require("models.community_tables")

local communities_c = {}

communities_c.GET = function(params)
	local db_community_entries = community_tables:find_all({params.table_id}, "table_id")

	return 200, {communities = db_community_entries}
end

return communities_c
