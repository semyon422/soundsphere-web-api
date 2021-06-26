local scores = require("models.scores")
local util = require("lapis.util")

local score_c = {}

score_c.GET = function(req, res, go)
	local db_score_entry = scores:find(req.params.score_id)

	res.body = util.to_json({score = db_score_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return score_c
