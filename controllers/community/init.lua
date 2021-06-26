local communities = require("models.communities")
local util = require("lapis.util")

local community_c = {}

community_c.GET = function(req, res, go)
	local db_community_entry = communities:find(req.params.community_id)

	res.body = util.to_json({community = db_community_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return community_c
