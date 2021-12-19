local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local Controller = require("Controller")
local community_user_c = require("controllers.community.user")

local additions = {
	inputmodes = require("controllers.community.inputmodes"),
	leaderboards = require("controllers.community.leaderboards"),
	users = require("controllers.community.users"),
}

local community_c = Controller:new()

community_c.path = "/communities/:community_id"
community_c.methods = {"GET", "PATCH", "DELETE"}
community_c.context = {"community"}
community_c.policies = {
	GET = require("policies.public"),
	PATCH = require("policies.public"),
	DELETE = require("policies.public"),
}

community_c.update_users = function(request, community_id, users)
	if not users then
		return
	end

	local community_user_ids = {}
	local community_users_map = {}
	for _, user in ipairs(users) do
		local community_user = user.community_user
		table.insert(community_user_ids, community_user.id)
		community_users_map[community_user.id] = community_user
		community_user.role = Roles:for_db(community_user.role)
	end

	if #community_user_ids == 0 then
		return
	end

	local community_users = Community_users:find_all(community_user_ids)

	for _, community_user in ipairs(community_users) do
		local policies = community_user_c.policies[method]
		if pep:check(request, policies) then
			local new_community_user = community_users_map[community_user.id]
			if community_user.role ~= new_community_user.role then
				community_user.role = new_community_user.role
				community_user:update("role")
			end
		end
	end
end

community_c.GET = function(request)
	local params = request.params
	local community = Communities:find(params.community_id)

	local fields = {}
	for param, controller in pairs(additions) do
		local value = tonumber(params[param])
		if value then
			local param_count = param .. "_count"
			params.per_page = value == 0 and value
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

community_c.DELETE = function(request)
	return 200, {}
end

return community_c
