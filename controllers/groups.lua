local Groups = require("models.groups")

local groups_c = {}

groups_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = Groups:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local groups = paginator:get_page(page_num)

	local count = Groups:count()

	return 200, {
		total = count,
		filtered = count,
		groups = groups
	}
end

return groups_c
