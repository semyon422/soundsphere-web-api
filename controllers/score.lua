local Scores = require("models.scores")

local score_c = {}

score_c.GET = function(params)
	local score = Scores:find(params.score_id)

	return 200, {score = score}
end

return score_c
