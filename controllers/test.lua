local Controller = require("Controller")
local util = require("util")

local test_c = Controller:new()

test_c.path = "/test"
test_c.methods = {"GET", "POST"}
test_c.captcha = true

test_c.policies.GET = {{"permit"}}
test_c.validations.GET = {
	{"params", type = "boolean", optional = true},
	{"query_exists", exists = true},
	{"query_number", type = "number"},
	{"query_boolean", type = "boolean"},
	{"recaptcha_token", type = "string", captcha = "test"},
}
test_c.GET = function(self)
	local params = self.params
	local response = {message = "success"}

	if params.params then
		response.params = params
	end
	if params.recaptcha_token then
		response.captcha = util.recaptcha_verify(params.recaptcha_token, self.context.ip)
	end

	return {json = response}
end

test_c.policies.POST = {{"permit"}}
test_c.validations.POST = {
	{"params", type = "boolean"},
	{"query_exists", exists = true},
	{"query_number", type = "number"},
	{"query_boolean", type = "boolean"},
	{"body_exists", exists = true},
	{"body_number", type = "number"},
	{"body_boolean", type = "boolean", param_type = "body"},
	{"body_table", type = "table", param_type = "body", validations = {
		{"body_table_exists", exists = true},
		{"body_table_table", type = "table", validations = {
			{"body_table_table_exists", exists = true},
		}}
	}},
	{"recaptcha_token", type = "string", param_type = "body", captcha = "test"},
}
test_c.POST = function(self)
	local params = self.params
	local response = {message = "success"}

	if params.params then
		response.params = params
	end
	if params.recaptcha_token then
		response.captcha = util.recaptcha_verify(params.recaptcha_token, self.context.ip)
	end

	return {json = response}
end

return test_c
