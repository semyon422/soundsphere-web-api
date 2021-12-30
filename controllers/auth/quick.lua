local hmac = require("openssl.hmac")
local digest = require("openssl.digest")
local users = require("models.users")
local quick_logins = require("models.quick_logins")
local login_c = require("controllers.auth.login")
local secret = require("secret")
local Controller = require("Controller")
local Ip = require("util.ip")

local quick_c = Controller:new()

quick_c.path = "/auth/quick"
quick_c.methods = {"GET", "POST"}

local function hex(str)
	return (str:gsub(".", function(c)
		return string.format("%02x", string.byte(c))
	end))
end

local new_key = function()
	return hex(digest.new("md5"):final(hmac.new(secret.token_key, "sha256"):final(ngx.time() + ngx.worker.pid())))
end

local messages = {}
messages.not_allowed = "Quick login is not allowed"
messages.success = "Success"

quick_c.policies.GET = {{"permit"}}
quick_c.validations.GET = {
	{"key", exists = true, type = "string"},
}
quick_c.GET = function(self)
	local params = self.params
	local ip = self.context.ip
	local time = os.time()
	local quick_login = quick_logins:find({ip = Ip:for_db(ip)})

	if not quick_login then
		local key = new_key()
		quick_logins:create({
			ip = Ip:for_db(ip),
			key = key,
			next_update_time = time + 5 * 60,
		})

		return {json = {key = key}}
	end

	if quick_login.next_update_time < time or not params.key then
		local key = new_key()
		quick_login.key = key
		quick_login.next_update_time = time + 5 * 60
		quick_login.complete = false
		quick_login:update("key", "next_update_time", "complete")

		return {json = {key = key}}
	end

	if quick_login.key ~= params.key or not quick_login.complete then
		return {json = {message = messages.not_allowed}}
	end

	local user = users:find(quick_login.user_id)
	if user then
		quick_login:delete()
		local token, payload = login_c.new_token(user, ip)

		return {
			json = {
				token = token,
				session = payload,
			}
		}
	end

	return {json = {message = messages.not_allowed}}
end

quick_c.context.POST = {"request_session"}
quick_c.policies.POST = {{"authenticated"}}
quick_c.validations.POST = {
	{"key", exists = true, type = "string"},
}
quick_c.POST = function(self)
	local key = self.params.key

	if not key then
		return {json = {message = messages.not_allowed}}
	end

	local quick_login = quick_logins:find({
		ip = Ip:for_db(self.context.ip),
		key = key
	})

	if not quick_login or quick_login.complete then
		return {json = {message = messages.not_allowed}}
	end

	quick_login.user_id = self.session.user_id
	quick_login.complete = true
	quick_login:update("user_id", "complete")

	return {json = {message = messages.success}}
end

return quick_c
