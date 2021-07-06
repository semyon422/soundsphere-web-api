local Scores = require("models.scores")

local score_c = {}

score_c.GET = function(params)
	local score = Scores:find(params.score_id)

	if score then
		return 200, {score = score}
	end

	return 404, {error = "Not found"}
end

return score_c
