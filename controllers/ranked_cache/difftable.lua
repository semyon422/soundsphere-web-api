local Difftable_notecharts = require("models.ranked_cache_difftables")
local util = require("util")
local Controller = require("Controller")

local ranked_cache_difftable_c = Controller:new()

ranked_cache_difftable_c.path = "/ranked_caches/:ranked_cache_id[%d]/difftables/:difftable_id[%d]"
ranked_cache_difftable_c.methods = {"GET", "PUT", "PATCH", "DELETE"}

ranked_cache_difftable_c.context.GET = {"ranked_cache_difftable"}
ranked_cache_difftable_c.policies.GET = {{"context_loaded"}}
ranked_cache_difftable_c.validations.GET = util.add_belongs_to_validations(Difftable_notecharts.relations)
ranked_cache_difftable_c.GET = function(self)
    local ranked_cache_difftable = self.context.ranked_cache_difftable

	util.get_relatives(ranked_cache_difftable, self.params, true)

	return {json = {ranked_cache_difftable = ranked_cache_difftable}}
end

ranked_cache_difftable_c.context.PUT = {
	"difftable",
	"ranked_cache",
	{"ranked_cache_difftable", missing = true},
	"request_session",
	"session_user",
	"user_roles",
}
ranked_cache_difftable_c.policies.PUT = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
ranked_cache_difftable_c.validations.PUT = {
	{"index", exists = true, type = "number", range = {0}},
	{"difficulty", type = "number", optional = true},
}
ranked_cache_difftable_c.PUT = function(self)
	local params = self.params

	local ranked_cache_difftable = Difftable_notecharts:create({
		ranked_cache_id = params.ranked_cache_id,
		difftable_id = params.difftable_id,
		index = params.index,
		difficulty = params.difficulty or 0,
	})

	return {json = {ranked_cache_difftable = ranked_cache_difftable}}
end

ranked_cache_difftable_c.context.PATCH = {"ranked_cache_difftable", "request_session", "session_user", "user_roles"}
ranked_cache_difftable_c.policies.PATCH = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
ranked_cache_difftable_c.validations.PATCH = {
	{"difficulty", exists = true, type = "number"},
}
ranked_cache_difftable_c.PATCH = function(self)
	local params = self.params

	local ranked_cache_difftable = self.context.ranked_cache_difftable
	ranked_cache_difftable.difficulty = params.difficulty
	ranked_cache_difftable:update("difficulty")

	return {json = {ranked_cache_difftable = ranked_cache_difftable}}
end

ranked_cache_difftable_c.context.DELETE = {"ranked_cache_difftable", "request_session", "session_user", "user_roles"}
ranked_cache_difftable_c.policies.DELETE = {
	{"authed", {role = "moderator"}},
	{"authed", {role = "admin"}},
	{"authed", {role = "creator"}},
}
ranked_cache_difftable_c.DELETE = function(self)
    local ranked_cache_difftable = self.context.ranked_cache_difftable
    ranked_cache_difftable:delete()

	return {status = 204}
end

return ranked_cache_difftable_c
