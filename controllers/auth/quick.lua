local rand = require("openssl.rand")
local Quick_logins = require("models.quick_logins")
local login_c = require("controllers.auth.login")
local Controller = require("Controller")
local Ip = require("util.ip")
local Filehash = require("util.filehash")

local quick_c = Controller:new()

quick_c.path = "/auth/quick"
quick_c.methods = {"GET", "POST", "PUT"}

local new_key = function()
	return rand.bytes(16)
end

quick_c.policies.GET = {{"permit"}}
quick_c.validations.GET = {
	{"key", type = "string", optional = true, nil_if = ""},
}
quick_c.GET = function(self)
	local key = self.params.key
	if key then
		return {json = {
			message = "Key passed, no new key generated",
			key = key,
		}}
	end

	local ip = self.context.ip
	local time = os.time()
	local quick_login = Quick_logins:find({ip = Ip:for_db(ip)})

	if not quick_login then
		key = new_key()
		Quick_logins:create({
			ip = Ip:for_db(ip),
			key = key,
			expires_at = time + 5 * 60,
		})
	else
		key = new_key()
		quick_login.key = key
		quick_login.expires_at = time + 5 * 60
		quick_login.complete = false
		quick_login:update("key", "expires_at", "complete")
	end

	return {json = {key = Filehash:to_name(key)}}
end

quick_c.policies.PUT = {{"permit"}}
quick_c.validations.PUT = {
	{"key", type = "string"},
}
quick_c.PUT = function(self)
	local ip = self.context.ip
	local key = Filehash:for_db(self.params.key)
	local quick_login = Quick_logins:find({
		ip = Ip:for_db(ip),
		key = key,
	})

	if not quick_login then
		return {status = 404, json = {message = "Quick login not found"}}
	elseif quick_login.expires_at < os.time() then
		return {status = 400, json = {message = "Quick login expired"}}
	elseif not quick_login.complete then
		return {status = 403, json = {message = "Not complete"}}
	end

	local user = quick_login:get_user()
	quick_login:delete()
	local token, payload = login_c.new_token(user, ip)
	login_c.add_user_location(user, ip, false)

	return {json = {
		token = token,
		session = payload,
	}}
end

quick_c.context.POST = {"request_session"}
quick_c.policies.POST = {{"authed"}}
quick_c.validations.POST = {
	{"key", type = "string"},
}
quick_c.POST = function(self)
	local ip = self.context.ip
	local key = Filehash:for_db(self.params.key)
	local quick_login = Quick_logins:find({
		ip = Ip:for_db(ip),
		key = key,
	})

	if not quick_login then
		return {status = 404, json = {message = "Quick login not found"}}
	elseif quick_login.expires_at < os.time() then
		return {status = 400, json = {message = "Quick login expired"}}
	elseif quick_login.complete then
		return {status = 403, json = {message = "Complete"}}
	end

	quick_login.user_id = self.session.user_id
	quick_login.complete = true
	quick_login:update("user_id", "complete")

	return {json = {message = "Success"}}
end

return quick_c
