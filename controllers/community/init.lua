local communities = require("models.communities")

local community_c = {}

community_c.GET = function(params)
	local community_entry = communities:find(params.community_id)

	return 200, {community = community_entry}
end

return community_c
