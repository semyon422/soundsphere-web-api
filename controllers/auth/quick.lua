local md5 = require("md5")
local users = require("models.users")
local quick_logins = require("models.quick_logins")
local login_c = require("controllers.auth.login")
local secret = require("secret")

local quick_c = {}

local new_key = function()
	return md5.sumhexa(crypto.hmac.digest("sha256", ngx.time() + ngx.worker.pid(), secret.token_key, true))
end

local not_allowed = "Quick login is not allowed"

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

		return 200, {json = {
			key = key
		}}
	end

	if tonumber(quick_login.next_update_time) < time or not params.key then
		local key = new_key()
		quick_login.key = key
		quick_login.next_update_time = time + 5 * 60
		quick_login.complete = 0
		quick_login:update("key", "next_update_time", "complete")

		return 200, {json = {
			key = key
		}}
	end

	if quick_login.key ~= params.key or quick_login.complete == 0 then
		return 200, {json = {
			message = not_allowed
		}}
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

	return 200, {json = {
		message = not_allowed
	}}
end

quick_c.POST = function(request)
	local params = request.params
	local context = request.context
	local user_id = params.user_id
	local key = params.key

	if not key or not user_id then
		return 200, {json = {
			message = not_allowed
		}}
	end

	local quick_login = quick_logins:find({
		ip = context.ip,
		key = key
	})

	if not quick_login or quick_login.complete == 1 then
		return 200, {json = {
			message = not_allowed
		}}
	end

	quick_login.user_id = user_id
	quick_login.complete = 1
	quick_login:update("user_id", "complete")

	return 200, {json = {}}
end

return quick_c
