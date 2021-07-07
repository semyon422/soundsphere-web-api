local Communities = require("models.communities")
local community_inputmodes_c = require("controllers.community.inputmodes")
local community_leaderboards_c = require("controllers.community.leaderboards")
local community_users_c = require("controllers.community.users")

local community_c = {}

community_c.GET = function(params)
	local community = Communities:find(params.community_id)

	if params.inputmodes then
		local _, response = community_inputmodes_c.GET(params)
		community.inputmodes = response.inputmodes
		community.inputmodes_count = response.total
	end
	if params.leaderboards then
		local _, response = community_leaderboards_c.GET(params)
		community.leaderboards = response.leaderboards
		community.leaderboards_count = response.total
	end
	if params.users then
		local _, response = community_users_c.GET(params)
		community.users = response.users
		community.users_count = response.total
	end

	return 200, {community = community}
end

community_c.PATCH = function(params)
	local community = Communities:find(params.community_id)

	community.name = params.community.name
	community.alias = params.community.alias
	community.short_description = params.community.short_description
	community.description = params.community.description

	community:update("name", "alias", "short_description", "description")

	return 200, {community = community}
end

return community_c
