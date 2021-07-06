local Communities = require("models.communities")

local community_c = {}

community_c.GET = function(params)
	local community = Communities:find(params.community_id)

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
