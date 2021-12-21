local md5 = require("md5")
local hmac = require("openssl.hmac")
local users = require("models.users")
local quick_logins = require("models.quick_logins")
local login_c = require("controllers.auth.login")
local secret = require("secret")
local Controller = require("Controller")

local quick_c = Controller:new()

quick_c.path = "/auth/quick"
quick_c.methods = {"GET", "POST"}

local new_key = function()
	return md5.sumhexa(hmac.new(secret.token_key, "sha256"):final(ngx.time() + ngx.worker.pid()))
end

local messages = {}
messages.not_allowed = "Quick login is not allowed"
messages.success = "Success"

quick_c.context.GET = {"session"}
quick_c.policies.GET = {{"permit"}}
quick_c.validations.GET = {
	{"key", exists = true, type = "string"},
}
quick_c.GET = function(request)
	local params = request.params
	local ip = request.context.ip
	local time = os.time()
	local quick_login = quick_logins:find({ip = ip})

	if not quick_login then
		local key = new_key()
		quick_logins:create({
			ip = ip,
			key = key,
			next_update_time = time + 5 * 60,
		})

		return 200, {key = key}
	end

	if quick_login.next_update_time < time or not params.key then
		local key = new_key()
		quick_login.key = key
		quick_login.next_update_time = time + 5 * 60
		quick_login.complete = false
		quick_login:update("key", "next_update_time", "complete")

		return 200, {key = key}
	end

	if quick_login.key ~= params.key or not quick_login.complete then
		return 200, {message = messages.not_allowed}
	end

	local user = users:find(quick_login.user_id)
	if user then
		quick_login:delete()
		local token, payload = login_c.new_token(user, ip)

		return 200, {
			token = token,
			session = payload,
		}
	end

	return 200, {message = messages.not_allowed}
end

quick_c.context.POST = {"session"}
quick_c.policies.POST = {{"authenticated"}}
quick_c.validations.POST = {
	{"key", exists = true, type = "string"},
}
quick_c.POST = function(request)
	local key = request.params.key

	if not key then
		return 200, {message = messages.not_allowed}
	end

	local quick_login = quick_logins:find({
		ip = request.context.ip,
		key = key
	})

	if not quick_login or quick_login.complete then
		return 200, {message = messages.not_allowed}
	end

	quick_login.user_id = request.context.session.user_id
	quick_login.complete = true
	quick_login:update("user_id", "complete")

	return 200, {message = messages.success}
end

return quick_c
