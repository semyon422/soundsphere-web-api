local Scores = require("models.scores")
local Controller = require("Controller")

local scores_c = Controller:new()

scores_c.path = "/scores"
scores_c.methods = {"GET", "POST"}

scores_c.policies.GET = {{"permit"}}
scores_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
}
scores_c.GET = function(request)
	local params = request.params
	local per_page = params.per_page or 10
	local per_page = params.page_num or 1

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

scores_c.policies.POST = {{"permit"}}
scores_c.POST = function(request)
	return 200, {}
end

return scores_c
