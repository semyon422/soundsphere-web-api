local rand = require("openssl.rand")
local Bypass_keys = require("models.bypass_keys")
local Bypass_actions = require("enums.bypass_actions")
local Controller = require("Controller")
local util = require("util")

local keys_c = Controller:new()

keys_c.path = "/auth/keys"
keys_c.methods = {"GET", "POST"}

keys_c.context.GET = {"request_session", "session_user", "user_roles"}
keys_c.policies.GET = {
	{"authed", {role = "moderator"}, {not_params = "all_creators"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
keys_c.validations.GET = {
	{"action", exists = true, type = "string", one_of = Bypass_actions.list, optional = true},
	{"all_actions", type = "boolean", optional = true},
	{"all_creators", type = "boolean", optional = true},
}
keys_c.GET = function(self)
	local params = self.params

	local where = {}
	if params.action and not params.all_actions then
		where.action = Bypass_actions:for_db(params.action)
	end
	if not params.all_creators then
		where.user_id = self.context.session_user.id
	end

	local db = Bypass_keys.db
	local bypass_keys
	if next(where) then
		bypass_keys = Bypass_keys:select("where " .. db.encode_clause(where))
	else
		bypass_keys = Bypass_keys:select()
	end

	for _, bypass_key in ipairs(bypass_keys) do
		bypass_key.is_expired = bypass_key.expires_at <= os.time()
	end

	util.recursive_to_name(bypass_keys)

	return {json = {bypass_keys = bypass_keys}}
end

keys_c.context.POST = {"request_session", "session_user", "user_roles"}
keys_c.policies.POST = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
keys_c.validations.POST = {
	{"action", exists = true, type = "string", one_of = Bypass_actions.list},
	{"expires_at", exists = true, type = "number", default = os.time() + 3600},
}
keys_c.POST = function(self)
	local params = self.params

	local bypass_key = Bypass_keys:create({
		key = rand.bytes(16),
		action = Bypass_actions:for_db(params.action),
		user_id = self.context.session_user.id,
		created_at = os.time(),
		expires_at = params.expires_at,
	})

	return {status = 201, redirect_to = self:url_for(bypass_key)}
end

return keys_c
