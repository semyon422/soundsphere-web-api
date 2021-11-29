local Difftables = require("models.difftables")

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

	local paginator = Difftables:paginated(
		"order by id asc",
		{
			per_page = per_page
		}
	)
	local difftables = paginator:get_page(page_num)

	local count = Difftables:count()

	return 200, {
		total = count,
		filtered = count,
		difftables = difftables
	}
end

difftables_c.POST = function(request)
	local params = request.params
	local difftable = params.difftable
	difftable = Difftables:create({
		name = difftable.name,
		url = difftable.url,
	})

	return 200, {difftable = difftable}
end

return difftables_c
