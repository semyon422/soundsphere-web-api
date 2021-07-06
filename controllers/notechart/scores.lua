local Scores = require("models.scores")

local notechart_c = {}

notechart_c.GET = function(params)
	local scores = Scores:find_all({params.notechart_id}, "notechart_id")

	local count = #scores

	return 200, {
		total = count,
		filtered = count,
		scores = scores
	}
end

return notechart_c
