local rand = require("openssl.rand")
local users = require("models.users")
local Quick_logins = require("models.quick_logins")
local login_c = require("controllers.auth.login")
local Controller = require("Controller")
local Ip = require("util.ip")
local Filehash = require("util.filehash")

local quick_c = Controller:new()

quick_c.path = "/auth/quick"
quick_c.methods = {"GET", "POST"}

local new_key = function()
	return rand.bytes(16)
end

local messages = {}
messages.not_allowed = "Quick login is not allowed"
messages.success = "Success"

quick_c.policies.GET = {{"permit"}}
quick_c.validations.GET = {
	{"key", exists = true, type = "string", optional = true},
}
quick_c.GET = function(self)
	local params = self.params
	local ip = self.context.ip
	local time = os.time()
	local quick_login = Quick_logins:find({ip = Ip:for_db(ip)})

	if not quick_login then
		if params.key then
			return {json = {message = messages.not_allowed}}
		end

		local key = new_key()
		Quick_logins:create({
			ip = Ip:for_db(ip),
			key = key,
			next_update_time = time + 5 * 60,
		})

		return {json = {key = Filehash:to_name(key)}}
	end

	if quick_login.next_update_time < time or not params.key then
		local key = new_key()
		quick_login.key = key
		quick_login.next_update_time = time + 5 * 60
		quick_login.complete = false
		quick_login:update("key", "next_update_time", "complete")

		return {json = {key = Filehash:to_name(key)}}
	end

	params.key = Filehash:for_db(params.key)
	if quick_login.key ~= params.key or not quick_login.complete then
		return {json = {message = messages.not_allowed}}
	end

	local user = users:find(quick_login.user_id)
	if user then
		quick_login:delete()
		local token, payload = login_c.new_token(user, ip)

		return {json = {
			token = token,
			session = payload,
		}}
	end

	return {json = {message = messages.not_allowed}}
end

quick_c.context.POST = {"request_session"}
quick_c.policies.POST = {{"authed"}}
quick_c.validations.POST = {
	{"key", exists = true, type = "string"},
}
quick_c.POST = function(self)
	local key = self.params.key

	if not key then
		return {json = {message = messages.not_allowed}}
	end

	key = Filehash:for_db(key)
	local quick_login = Quick_logins:find({
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
