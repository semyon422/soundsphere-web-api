local Ranked_caches = require("models.ranked_caches")
local Controller = require("Controller")
local util = require("util")

local ranked_cache_c = Controller:new()

ranked_cache_c.path = "/ranked_caches/:ranked_cache_id[%d]"
ranked_cache_c.methods = {"GET", "DELETE"}

ranked_cache_c.context.GET = {"ranked_cache"}
ranked_cache_c.policies.GET = {{"permit"}}
util.add_belongs_to_validations(Ranked_caches.relations, ranked_cache_c.validations.GET)
ranked_cache_c.GET = function(self)
	local ranked_cache = self.context.ranked_cache
	util.get_relatives(ranked_cache, self.params, true)

	return {json = {ranked_cache = ranked_cache:to_name()}}
end

ranked_cache_c.context.DELETE = {"ranked_cache", "request_session", "session_user", "user_roles"}
ranked_cache_c.policies.DELETE = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
ranked_cache_c.DELETE = function(self)
	self.context.ranked_cache:delete()
	return {status = 204}
end

return ranked_cache_c
