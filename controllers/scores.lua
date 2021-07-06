local Scores = require("models.scores")

local scores_c = {}

scores_c.GET = function(params)
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = Scores:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local scores = paginator:get_page(page_num)

	local count = Scores:count()

	return 200, {
		total = count,
		filtered = count,
		scores = scores
	}
end

return scores_c
