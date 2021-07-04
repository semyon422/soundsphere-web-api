local scores = require("models.scores")

local notechart_c = {}

notechart_c.GET = function(params)
	local db_score_entries = scores:find_all({params.notechart_id}, "notechart_id")

	return 200, {scores = db_score_entries}
end

return notechart_c
