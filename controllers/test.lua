local Scores = require("models.scores")
local Controller = require("Controller")

local test_c = Controller:new()

test_c.path = "/test"
test_c.methods = {"GET", "POST"}

test_c.policies.GET = {{"permit"}}
test_c.validations.GET = {
	{"params", type = "boolean"},
	{"query_exists", exists = true},
	{"query_number", exists = true, type = "number"},
	{"query_boolean", type = "boolean"},
}
test_c.GET = function(request)
	return 200, {message = "success"}
end

test_c.policies.POST = {{"permit"}}
test_c.validations.POST = {
	{"params", type = "boolean"},
	{"query_exists", exists = true},
	{"query_number", exists = true, type = "number"},
	{"query_boolean", type = "boolean"},
	{"body_exists", exists = true},
	{"body_number", exists = true, type = "number"},
	{"body_boolean", type = "boolean", param_type = "body"},
	{"body_table", exists = true, type = "table", param_type = "body", validations = {
		{"body_table_exists", exists = true},
		{"body_table_table", exists = true, type = "table", validations = {
			{"body_table_table_exists", exists = true},
		}}
	}},
}
test_c.POST = function(request)
	return 200, {message = "success"}
end

return test_c
