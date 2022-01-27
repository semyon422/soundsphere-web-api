local Controller = require("Controller")
local Bypass_keys = require("models.bypass_keys")
local util = require("util")

local keys_c = Controller:new()

keys_c.path = "/auth/keys/:key_id[%d]"
keys_c.methods = {"GET", "DELETE"}

keys_c.context.GET = {"bypass_key", "request_session", "session_user", "user_roles"}
keys_c.policies.GET = {
	{"authed", {role = "moderator"}, "bypass_key_creator"},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
keys_c.validations.GET = {}
util.add_belongs_to_validations(Bypass_keys.relations, keys_c.validations.GET)
keys_c.GET = function(self)
	local bypass_key = self.context.bypass_key

	bypass_key.is_expired = bypass_key.expires_at <= os.time()
	util.get_relatives(bypass_key, self.params, true)

	return {json = {bypass_key = bypass_key:to_name()}}
end

keys_c.context.DELETE = {"bypass_key", "request_session", "session_user", "user_roles"}
keys_c.policies.DELETE = {
	{"authed", {role = "moderator"}, "bypass_key_creator"},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
keys_c.DELETE = function(self)
	self.context.bypass_key:delete()

	return {status = 204}
end

return keys_c
