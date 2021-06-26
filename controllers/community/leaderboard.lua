local community_leaderboards = require("models.community_leaderboards")
local util = require("lapis.util")

local community_leaderboards_c = {}

community_leaderboards_c.PUT = function(req, res, go)
    local entry = {
        community_id = req.params.community_id,
        leaderboard_id = req.params.leaderboard_id,
    }
    local community_leaderboard = community_leaderboards:find(entry)
    if not community_leaderboard then
        community_leaderboards:create(entry)
    end

	res.body = util.to_json({community_leaderboard = entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

community_leaderboards_c.DELETE = function(req, res, go)
    local entry = {
        community_id = req.params.community_id,
        leaderboard_id = req.params.leaderboard_id,
    }
    local community_leaderboard = community_leaderboards:find(entry)
    if community_leaderboard then
        community_leaderboard:delete()
    end

	res.body = util.to_json({})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return community_leaderboards_c
