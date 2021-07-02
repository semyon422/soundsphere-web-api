local scores = require("models.scores")
local util = require("lapis.util")

local score_c = {}

score_c.GET = function(params)
	local db_score_entry = scores:find(params.score_id)

	if db_score_entry then
		return 200, {score = db_score_entry}
	end

	return 404, {error = "Not found"}
end

return score_c
