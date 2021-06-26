local formats = require("models.formats")
local util = require("lapis.util")

local format_c = {}

format_c.GET = function(req, res, go)
	local db_format_entry = formats:find(req.params.format_id)

	res.body = util.to_json({format = db_format_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return format_c
