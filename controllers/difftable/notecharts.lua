local Difftable_notecharts = require("models.difftable_notecharts")
local Joined_query = require("util.joined_query")
local preload = require("lapis.db.model").preload
local util = require("util")
local Controller = require("Controller")

local difftable_notecharts_c = Controller:new()

difftable_notecharts_c.path = "/difftables/:difftable_id[%d]/notecharts"
difftable_notecharts_c.methods = {"GET"}

difftable_notecharts_c.policies.GET = {{"permit"}}
difftable_notecharts_c.validations.GET = {
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
}
util.add_belongs_to_validations(Difftable_notecharts.relations, difftable_notecharts_c.validations.GET)
difftable_notecharts_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local jq = Joined_query:new(Difftable_notecharts.db)
	jq:select("dn")
	jq:where("dn.difftable_id = ?", params.difftable_id)
	jq:orders("dn.id asc")
	jq:fields("dn.*")

	local user_id = self.session.user_id
	if user_id then
		jq:select("left join scores s on dn.notechart_id = s.notechart_id and s.user_id = ?", user_id)
		jq:where("s.is_top = ?", true)
		jq:fields("s.user_id")
	end

	local query, options = jq:concat()
	options.per_page = per_page

	local paginator = Difftable_notecharts:paginated(query, options)
	local difftable_notecharts = paginator:get_page(page_num)

	local count = tonumber(util.db_count(Difftable_notecharts, query))
	if params.no_data then
		return {json = {
			total = count,
			filtered = count,
		}}
	end

	preload(difftable_notecharts, util.get_relatives_preload(Difftable_notecharts, params))
	util.recursive_to_name(difftable_notecharts)

	for _, difftable_notechart in ipairs(difftable_notecharts) do
		if difftable_notechart.user_id then
			difftable_notechart.is_played = true
			difftable_notechart.user_id = nil
		end
	end

	return {json = {
		total = count,
		filtered = count,
		difftable_notecharts = difftable_notecharts,
	}}
end

return difftable_notecharts_c
