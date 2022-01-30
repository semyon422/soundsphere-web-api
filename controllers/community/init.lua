local Communities = require("models.communities")
local Leaderboards = require("models.leaderboards")
local Difftables = require("models.difftables")
local Controller = require("Controller")
local community_users_c = require("controllers.community.users")
local util = require("util")

local additions = {
	inputmodes = require("controllers.community.inputmodes"),
	leaderboards = require("controllers.community.leaderboards"),
	users = require("controllers.community.users"),
	difftables = require("controllers.community.difftables"),
}

local community_c = Controller:new()

community_c.path = "/communities/:community_id[%d]"
community_c.methods = {"GET", "PATCH", "DELETE"}

community_c.update_users = function(self, community_users)
	return community_users_c.update_users(self, community_users)
end

community_c.context.GET = {"community"}
community_c.policies.GET = {{"context_loaded"}}
community_c.validations.GET = {}
util.add_additions_validations(additions, community_c.validations.GET)
util.add_belongs_to_validations(Communities.relations, community_c.validations.GET)
community_c.GET = function(self)
	local params = self.params
	local community = self.context.community

	util.get_relatives(community, params, true)
	util.load_additions(self, community, additions)

	return {json = {community = community}}
end

community_c.context.PATCH = {"community", "request_session", "session_user", "user_communities", "user_roles"}
community_c.display_policies.PATCH = {
	{"authed", {community_role = "admin"}},
	{"authed", {community_role = "creator"}},
}
community_c.policies.PATCH = {
	{"authed", {community_role = "admin"}, "community_patch"},
	{"authed", {community_role = "creator"}, "community_patch"},
}
community_c.validations.PATCH = {
	{"community", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"alias", exists = true, type = "string"},
		{"link", exists = true, type = "string"},
		{"short_description", exists = true, type = "string"},
		{"description", exists = true, type = "string"},
		{"banner", exists = true, type = "string", optional = true},
		{"is_public", type = "boolean"},
		{"default_leaderboard_id", exists = true, type = "number"},
	}},
}
community_c.PATCH = function(self)
	local params = self.params
	local community = self.context.community

	local found_community =
		Communities:find({name = params.community.name}) or
		Communities:find({alias = params.community.alias})
	if found_community and found_community.id ~= community.id then
		return {status = 400, json = {message = "This name is already taken"}}
	end

	util.patch(community, params.community, {
		"name",
		"alias",
		"link",
		"short_description",
		"description",
		"banner",
		"is_public",
		"default_leaderboard_id",
	})
	local community_users = community_c.update_users(self, params.community.community_users)
	if community_users then
		community.community_users = community_users
	end

	util.recursive_to_name(community)

	return {json = {community = community}}
end

community_c.context.DELETE = {"community", "request_session", "session_user", "user_communities"}
community_c.policies.DELETE = {
	{"authed", {community_role = "creator"}},
}
community_c.DELETE = function(self)
	local community = self.context.community

	local leaderboards = Leaderboards:find_all({community.id}, "owner_community_id")
	if #leaderboards > 0 then
		return {status = 400, json = {message = "#leaderboards > 0"}}
	end

	local difftables = Difftables:find_all({community.id}, "owner_community_id")
	if #difftables > 0 then
		return {status = 400, json = {message = "#difftables > 0"}}
	end

	local db = Communities.db
	db.delete("community_leaderboards", {community_id = community.id})
	db.delete("community_users", {community_id = community.id})
	db.delete("community_difftables", {community_id = community.id})
	db.delete("community_inputmodes", {community_id = community.id})
	db.delete("community_changes", {community_id = community.id})

	community:delete()

	return {status = 204}
end

return community_c
