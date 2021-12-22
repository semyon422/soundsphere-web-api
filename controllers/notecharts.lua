local Notecharts = require("models.notecharts")
local Controller = require("Controller")

local notecharts_c = Controller:new()

notecharts_c.path = "/notecharts"
notecharts_c.methods = {"GET", "POST"}

notecharts_c.policies.GET = {{"permit"}}
notecharts_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
}
notecharts_c.GET = function(request)
	local params = request.params
	local per_page = params.per_page or 10
	local per_page = params.page_num or 1

	local paginator = Notecharts:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local notecharts = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	local count = Notecharts:count()

	return 200, {
		total = count,
		filtered = count,
		notecharts = notecharts
	}
end

return notecharts_c
