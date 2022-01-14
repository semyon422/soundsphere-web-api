local Notecharts = require("models.notecharts")
local Controller = require("Controller")
local util = require("util")
local preload = require("lapis.db.model").preload

local notecharts_c = Controller:new()

notecharts_c.path = "/notecharts"
notecharts_c.methods = {"GET", "POST"}

notecharts_c.policies.GET = {{"permit"}}
notecharts_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
}
util.add_belongs_to_validations(Notecharts.relations, notecharts_c.validations.GET)
util.add_has_many_validations(Notecharts.relations, notecharts_c.validations.GET)
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
	local notecharts = paginator:get_page(page_num)
	preload(notecharts, util.get_relatives_preload(Notecharts, params))
	util.recursive_to_name(notecharts)

	local count = tonumber(Notecharts:count())

	return {json = {
		total = count,
		filtered = count,
		notecharts = notecharts,
	}}
end

return notecharts_c
