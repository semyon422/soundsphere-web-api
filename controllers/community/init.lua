local communities = require("models.communities")

local community_c = {}

community_c.GET = function(params)
	return communities:find(params.community_id)
end

return community_c
