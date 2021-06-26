local notecharts = require("models.notecharts")
local util = require("lapis.util")

local notechart_c = {}

notechart_c.GET = function(req, res, go)
	local db_notechart_entry = notecharts:find(req.params.notechart_id)

	res.body = util.to_json({notechart = db_notechart_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return notechart_c
