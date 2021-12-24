local Difftables = require("models.difftables")
local Inputmodes = require("enums.inputmodes")
local db_search = require("util.db_search")
local db_where = require("util.db_where")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local difftables_c = Controller:new()

difftables_c.path = "/difftables"
difftables_c.methods = {"GET", "POST"}

difftables_c.policies.GET = {{"permit"}}
difftables_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
	require("validations.search"),
	{"inputmodes", type = "boolean", optional = true},
}
difftables_c.GET = function(request)
	local params = request.params
	local per_page = params.per_page or 10
	local per_page = params.page_num or 1

	local relations = {}
	if params.inputmodes then
		table.insert(relations, "difftable_inputmodes")
	end

	local clause = params.search and db_search(Difftables.db, params.search, "name")
	local paginator = Difftables:paginated(
		db_where(clause), "order by id asc",
		{
			per_page = per_page,
			prepare_results = function(entries)
				preload(entries, relations)
				return entries
			end
		}
	)
	local difftables = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	for _, difftable in ipairs(difftables) do
		if params.inputmodes then
			difftable.inputmodes = Inputmodes:entries_to_list(difftable.difftable_inputmodes)
			difftable.difftable_inputmodes = nil
		end
	end

	return 200, {
		total = Difftables:count(),
		filtered = Difftables:count(clause),
		difftables = difftables
	}
end

difftables_c.policies.POST = {{"permit"}}
difftables_c.validations.POST = {
	{"difftable", exists = true, type = "table", body = true, validations = {
		{"name", exists = true, type = "string"},
		{"link", exists = true, type = "string"},
		{"description", exists = true, type = "string"},
		{"owner_community_id", exists = true, type = "number"},
	}}
}
difftables_c.POST = function(request)
	local params = request.params
	local difftable = params.difftable
	difftable = Difftables:create({
		name = difftable.name or "Difficulty table",
		link = difftable.link,
		description = difftable.description,
		owner_community_id = params.community_id,
	})

	return 200, {difftable = difftable}
end

return difftables_c
