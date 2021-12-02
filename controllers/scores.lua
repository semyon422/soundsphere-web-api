local Scores = require("models.scores")

local scores_c = {}

scores_c.path = "/scores"
scores_c.methods = {"GET", "POST"}
scores_c.context = {}
scores_c.policies = {
	GET = require("policies.public"),
	POST = require("policies.public"),
}

scores_c.GET = function(request)
	local params = request.params
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = Scores:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local scores = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	local count = Scores:count()

	return 200, {
		total = count,
		filtered = count,
		scores = scores
	}
end

scores_c.POST = function(request)
	return 200, {}
end

return scores_c
