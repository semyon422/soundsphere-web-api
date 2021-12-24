local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local Controller = require("Controller")
local community_users_c = require("controllers.community.users")

local additions = {
	inputmodes = require("controllers.community.inputmodes"),
	leaderboards = require("controllers.community.leaderboards"),
	users = require("controllers.community.users"),
}

local community_c = Controller:new()

community_c.path = "/communities/:community_id[%d]"
community_c.methods = {"GET", "PATCH", "DELETE"}

community_c.update_users = function(request, community_id, users)
	return community_users_c.update_users(request, community_id, users)
end

community_c.context.GET = {"community"}
community_c.policies.GET = {{"permit"}}
community_c.validations.GET = {
	{"inputmodes", type = "boolean", optional = true},
	{"leaderboards", type = "boolean", optional = true},
	{"users", type = "boolean", optional = true},
}
community_c.GET = function(request)
	local params = request.params
	local community = request.context.community

	local fields = {}
	for param, controller in pairs(additions) do
		local value = params[param]
		if value ~= nil then
			local param_count = param .. "_count"
			params.no_data = value == false
			local _, response = controller.GET(request)
			community[param] = response[param]
			if community[param_count] and community[param_count] ~= response.total then
				community[param_count] = response.total
				table.insert(fields, param_count)
			end
		end
	end
	if #fields > 0 then
		community:update(unpack(fields))
	end

	return 200, {community = community}
end

community_c.context.PATCH = {"community"}
community_c.policies.PATCH = {{"permit"}}
community_c.PATCH = function(request)
	local params = request.params
	local community = Communities:find(params.community_id)

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

	community_c.update_users(request, community.id, params.community.users)

	return 200, {community = community}
end

community_c.context.DELETE = {"community"}
community_c.policies.DELETE = {{"permit"}}
community_c.DELETE = function(request)
	return 200, {}
end

return community_c
