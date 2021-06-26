local community_users = require("models.community_users")
local util = require("lapis.util")

local community_users_c = {}

community_users_c.PUT = function(req, res, go)
    local entry = {
        community_id = req.params.community_id,
        user_id = req.params.user_id,
    }
    local community_user = community_users:find(entry)
    if not community_user then
        community_users:create(entry)
    end

	res.body = util.to_json({community_user = entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

community_users_c.DELETE = function(req, res, go)
    local entry = {
        community_id = req.params.community_id,
        user_id = req.params.user_id,
    }
    local community_user = community_users:find(entry)
    if community_user then
        community_user:delete()
    end

	res.body = util.to_json({})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return community_users_c
