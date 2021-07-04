local groups = require("models.groups")
local util = require("lapis.util")

local groups_c = {}

groups_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = groups:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_group_entries = paginator:get_page(page_num)

	local count = groups:count()

	return 200, {
		total = count,
		filtered = count,
		groups = db_group_entries
	}
end

return groups_c
