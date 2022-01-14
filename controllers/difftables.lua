local Difftables = require("models.difftables")
local Inputmodes = require("enums.inputmodes")
local util = require("util")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local difftables_c = Controller:new()

difftables_c.path = "/difftables"
difftables_c.methods = {"GET", "POST"}

difftables_c.policies.GET = {{"permit"}}
difftables_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
}
util.add_belongs_to_validations(Difftables.relations, difftables_c.validations.GET)
util.add_has_many_validations(Difftables.relations, difftables_c.validations.GET)
difftables_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local clause = params.search and util.db_search(Difftables.db, params.search, "name")
	local paginator = Difftables:paginated(
		util.db_where(clause) .. " order by id asc",
		{
			per_page = per_page,
		}
	)
	local difftables = paginator:get_page(page_num)
	preload(difftables, util.get_relatives_preload(Difftables, params))
	util.recursive_to_name(difftables)

	return {json = {
		total = tonumber(Difftables:count()),
		filtered = tonumber(Difftables:count(clause)),
		difftables = difftables,
	}}
end

difftables_c.policies.POST = {{"permit"}}
difftables_c.validations.POST = {
	{"difftable", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"link", exists = true, type = "string"},
		{"description", exists = true, type = "string"},
		{"owner_community_id", exists = true, type = "number"},
	}}
}
difftables_c.POST = function(self)
	local params = self.params
	local difftable = params.difftable
	difftable = Difftables:create({
		name = difftable.name or "Difficulty table",
		link = difftable.link,
		description = difftable.description,
		owner_community_id = params.community_id,
	})

	return {status = 201, redirect_to = self:url_for(difftable)}
end

return difftables_c
