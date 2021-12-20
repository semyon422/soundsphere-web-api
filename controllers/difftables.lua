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
difftables_c.GET = function(request)
	local params = request.params
	local per_page = params.per_page or 10
	local per_page = params.page_num or 1

	local clause = params.search and db_search(Difftables.db, params.search, "name")
	local paginator = Difftables:paginated(
		db_where(clause), "order by id asc",
		{
			per_page = per_page,
			prepare_results = function(entries)
				preload(entries, "difftable_inputmodes")
				return entries
			end
		}
	)
	local difftables = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	for _, difftable in ipairs(difftables) do
		difftable.inputmodes = Inputmodes:entries_to_list(difftable:get_difftable_inputmodes())
		difftable.difftable_inputmodes = nil
	end

	return 200, {
		total = Difftables:count(),
		filtered = Difftables:count(clause),
		difftables = difftables
	}
end

difftables_c.policies.POST = {{"permit"}}
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
