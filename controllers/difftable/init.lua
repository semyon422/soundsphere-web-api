local Difftables = require("models.difftables")
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
	{"context_loaded", "authenticated", {community_role = "admin"}},
	{"context_loaded", "authenticated", {community_role = "creator"}},
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
	{"context_loaded", "authenticated", {community_role = "admin"}},
	{"context_loaded", "authenticated", {community_role = "creator"}},
}
difftable_c.DELETE = function(self)
	return {status = 204}
end

return difftable_c
