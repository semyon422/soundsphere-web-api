local communities = require("models.communities")
local util = require("lapis.util")

local communities_c = {}

communities_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = communities:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_community_entries = paginator:get_page(page_num)

	return 200, {communities = db_community_entries}
end

return communities_c
