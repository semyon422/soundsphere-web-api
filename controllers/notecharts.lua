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
notecharts_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local paginator = Notecharts:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local notecharts = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	for _, notechart in ipairs(notecharts) do
		notechart:to_name()
	end

	local count = Notecharts:count()

	return {json = {
		total = count,
		filtered = count,
		notecharts = notecharts,
	}}
end

return notecharts_c
