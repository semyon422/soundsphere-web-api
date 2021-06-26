local community_users = require("models.community_users")
local util = require("lapis.util")
local preload = require("lapis.db.model").preload

local community_users_c = {}

community_users_c.GET = function(req, res, go)
    local sub_community_users = community_users:find_all({req.params.community_id}, "community_id")

	res.body = util.to_json({users = sub_community_users})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return community_users_c
