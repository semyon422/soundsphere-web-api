local Tables = require("models.difftables")

local difftable_c = {}

difftable_c.path = "/difftables/:difftable_id"
difftable_c.methods = {"GET", "PATCH", "DELETE"}
difftable_c.context = {"difftable"}
difftable_c.policies = {
	GET = require("policies.public"),
}

difftable_c.GET = function(request)
	local params = request.params
	local difftable = Tables:find(params.difftable_id)

	if difftable then
		return 200, {difftable = difftable}
	end

	return 404, {error = "Not found"}
end

difftable_c.PATCH = function(request)
	return 200, {}
end

difftable_c.DELETE = function(request)
	return 200, {}
end

return difftable_c
