local Communities = require("models.communities")
local Controller = require("Controller")
local community_users_c = require("controllers.community.users")
local util = require("util")

local additions = {
	community_inputmodes = require("controllers.community.inputmodes"),
	community_leaderboards = require("controllers.community.leaderboards"),
	community_users = require("controllers.community.users"),
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
	util.load_additions(self, community, params, additions)

	return {json = {community = community}}
end

community_c.context.PATCH = {"community", "request_session"}
community_c.policies.PATCH = {{"authenticated", "context_loaded"}}
community_c.PATCH = function(self)
	local params = self.params
	local community = self.context.community

	community.name = params.community.name
	community.alias = params.community.alias
	community.link = params.community.link
	community.short_description = params.community.short_description
	community.description = params.community.description
	community.banner = params.community.banner
	community.is_public = params.community.is_public
	community.default_leaderboard_id = params.community.default_leaderboard_id

	community:update(
		"name",
		"alias",
		"link",
		"short_description",
		"description",
		"banner",
		"is_public",
		"default_leaderboard_id"
	)

	community_c.update_users(self, params.community.community_users)

	return {json = {community = community}}
end

community_c.context.DELETE = {"community"}
community_c.policies.DELETE = {{"permit"}}
community_c.DELETE = function(self)
	return {status = 204}
end

return community_c
