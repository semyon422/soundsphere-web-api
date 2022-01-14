local Controller = require("Controller")
local http = require("lapis.nginx.http")
local util = require("lapis.util")
local secret = require("secret")

local test_c = Controller:new()

test_c.path = "/test"
test_c.methods = {"GET", "POST"}
test_c.captcha = true

test_c.policies.GET = {{"permit"}}
test_c.validations.GET = {
	{"params", type = "boolean", optional = true},
	{"query_exists", exists = true},
	{"query_number", exists = true, type = "number"},
	{"query_boolean", type = "boolean"},
	{"recaptcha_token", exists = true, type = "string", captcha = "test"},
}
test_c.GET = function(self)
	local params = self.params
	local response = {message = "success"}

	if params.params then
		response.params = params
	end
	if params.recaptcha_token then
		local body, status_code, headers = http.simple("https://www.google.com/recaptcha/api/siteverify", {
			secret = secret.recaptcha_secret_key,
			response = params.recaptcha_token,
			remoteip = self.context.ip
		})
		response.captcha = util.from_json(body)
	end

	return {json = response}
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
	{"recaptcha_token", exists = true, type = "string", param_type = "body", captcha = "test"},
}
test_c.POST = function(self)
	local response = {message = "success"}
	if self.params.params then
		response.params = self.params
	end
	return {json = response}
end

return test_c
