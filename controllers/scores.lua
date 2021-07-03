local scores = require("models.scores")

local scores_c = {}

scores_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = scores:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local db_score_entries = paginator:get_page(page_num)

	local count = scores:count()

	return 200, {
		total = count,
		filtered = count,
		scores = db_score_entries
	}
end

return scores_c
