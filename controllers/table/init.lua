local Tables = require("models.tables")

local table_c = {}

table_c.path = "/tables/:table_id"
table_c.methods = {"GET", "PATCH", "DELETE"}
table_c.context = {"table"}
table_c.policies = {
	GET = require("policies.public"),
}

table_c.GET = function(request)
	local params = request.params
	local table = Tables:find(params.table_id)

	if table then
		return 200, {table = table}
	end

	return 404, {error = "Not found"}
end

table_c.PATCH = function(request)
	return 200, {}
end

table_c.DELETE = function(request)
	return 200, {}
end

return table_c
