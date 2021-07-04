local scores = require("models.scores")

local notechart_c = {}

notechart_c.GET = function(params)
	local db_score_entries = scores:find_all({params.notechart_id}, "notechart_id")

	local count = #db_score_entries

	return 200, {
		total = count,
		filtered = count,
		scores = db_score_entries
	}
end

return notechart_c
