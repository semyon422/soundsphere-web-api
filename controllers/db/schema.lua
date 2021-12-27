local Controller = require("Controller")

local schema_c = Controller:new()

schema_c.path = "/db/schema"
schema_c.methods = {"GET", "POST"}

schema_c.context.GET = {"session"}
schema_c.policies.GET = {{"authenticated"}}
schema_c.GET = function(request)
	return 200, {}
end

schema_c.context.POST = {"session"}
schema_c.policies.POST = {{"authenticated"}}
schema_c.validations.POST = {
	{"db_test", type = "boolean", optional = true},
}
schema_c.POST = function(request)
	local params = request.params

	if params.db_test then
		local db_test = require("db_test")
		db_test.create()
		return 200, {}
	end

	db.drop()
	db.create()

	return 200, {}
end

return schema_c
