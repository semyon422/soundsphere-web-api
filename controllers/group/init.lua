local groups = require("models.groups")
local util = require("lapis.util")

local group_c = {}

group_c.GET = function(req, res, go)
	local db_group_entry = groups:find(req.params.group_id)

	res.body = util.to_json({group = db_group_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return group_c
