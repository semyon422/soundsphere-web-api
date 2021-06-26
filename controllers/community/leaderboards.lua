local community_leaderboards = require("models.community_leaderboards")
local util = require("lapis.util")
local preload = require("lapis.db.model").preload

local community_leaderboards_c = {}

community_leaderboards_c.GET = function(req, res, go)
    local sub_community_leaderboards = community_leaderboards:find_all({req.params.community_id}, "community_id")
	preload(sub_community_leaderboards, "leaderboard")

	res.body = util.to_json({leaderboards = sub_community_leaderboards})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return community_leaderboards_c
