local Controller = require("Controller")
local db = require("db")

local schema_c = Controller:new()

schema_c.path = "/db/schema"
schema_c.methods = {"GET", "POST"}

schema_c.context.GET = {"request_session"}
schema_c.policies.GET = {{"authed"}}
schema_c.GET = function(self)
	return {}
end

schema_c.context.POST = {"request_session", "session_user", "user_roles"}
schema_c.policies.POST = {
	{"authed", {role = "creator"}},
	{"authed", {role = "admin"}},
}
schema_c.validations.POST = {
	{"db_test", type = "boolean", optional = true},
}
schema_c.POST = function(self)
	local params = self.params

	if params.db_test then
		local db_test = require("db_test")
		db_test.create()
		return {}
	end

	db.drop()
	db.create()

	return {}
end

return schema_c
