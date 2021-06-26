local tables = require("models.tables")
local util = require("lapis.util")

local table_c = {}

table_c.GET = function(req, res, go)
	local db_table_entry = tables:find(req.params.table_id)

	res.body = util.to_json({table = db_table_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return table_c
