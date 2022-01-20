local Difftables = require("models.difftables")
local Communities = require("models.communities")
local Controller = require("Controller")
local util = require("util")

local additions = {
	communities = require("controllers.difftable.communities"),
	leaderboards = require("controllers.difftable.leaderboards"),
	notecharts = require("controllers.difftable.notecharts"),
	inputmodes = require("controllers.difftable.inputmodes"),
}

local difftable_c = Controller:new()

difftable_c.path = "/difftables/:difftable_id[%d]"
difftable_c.methods = {"GET", "PATCH", "DELETE"}

local set_community_id = function(self)
	self.params.community_id = self.context.difftable.owner_community_id
	return true
end

difftable_c.context.GET = {"difftable"}
difftable_c.policies.GET = {{"context_loaded"}}
difftable_c.validations.GET = {}
util.add_additions_validations(additions, difftable_c.validations.GET)
util.add_belongs_to_validations(Difftables.relations, difftable_c.validations.GET)
difftable_c.GET = function(self)
	local params = self.params
	local difftable = self.context.difftable

	util.get_relatives(difftable, self.params, true)
	util.load_additions(self, difftable, additions)

	return {json = {difftable = difftable}}
end

difftable_c.context.PATCH = {"difftable", "request_session", "session_user", "user_communities", set_community_id}
difftable_c.policies.PATCH = {
	{"authed", {community_role = "admin"}},
	{"authed", {community_role = "creator"}},
}
difftable_c.validations.PATCH = {
	{"difftable", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"link", exists = true, type = "string"},
		{"description", exists = true, type = "string"},
		{"owner_community_id", exists = true, type = "number"},
	}}
}
difftable_c.PATCH = function(self)
	local params = self.params
	local difftable = self.context.difftable

	local found_difftable = Difftables:find({name = params.difftable.name})
	if found_difftable and found_difftable.id ~= difftable.id then
		return {status = 400, json = {message = "This name is already taken"}}
	end

	local community = Communities:find(params.difftable.owner_community_id)
	if not community then
		return {status = 400, json = {message = "not community"}}
	end

	util.patch(difftable, params.difftable, {
		"name",
		"link",
		"description",
		"owner_community_id",
	})

	return {json = {difftable = difftable}}
end

difftable_c.context.DELETE = {"difftable", "request_session", "session_user", "user_communities", set_community_id}
difftable_c.policies.DELETE = {
	{"authed", {community_role = "admin"}},
	{"authed", {community_role = "creator"}},
}
difftable_c.DELETE = function(self)
	local difftable = self.context.difftable

	local db = Difftables.db
	db.delete("difftable_notecharts", {difftable_id = difftable.id})
	db.delete("difftable_inputmodes", {difftable_id = difftable.id})
	db.delete("community_difftables", {difftable_id = difftable.id})
	db.delete("ranked_cache_difftables", {difftable_id = difftable.id})

	difftable:delete()

	return {status = 204}
end

return difftable_c
