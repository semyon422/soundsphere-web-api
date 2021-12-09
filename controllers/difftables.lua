local Difftables = require("models.difftables")
local Community_difftables = require("models.community_difftables")
local Inputmodes = require("enums.inputmodes")
local db_search = require("util.db_search")
local db_where = require("util.db_where")
local preload = require("lapis.db.model").preload

local difftables_c = {}

difftables_c.path = "/difftables"
difftables_c.methods = {"GET", "POST"}
difftables_c.context = {}
difftables_c.policies = {
	GET = require("policies.public"),
	POST = require("policies.public"),
}

difftables_c.GET = function(request)
	local params = request.params
	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

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

difftables_c.POST = function(request)
	local params = request.params
	local difftable = params.difftable
	difftable = Difftables:create({
		name = difftable.name or "Difficulty table",
		link = difftable.link,
		description = difftable.description,
	})

	Community_difftables:create({
		community_id = params.community_id,
		difftable_id = difftable.id,
		is_owner = true,
	})

	return 200, {difftable = difftable}
end

return difftables_c