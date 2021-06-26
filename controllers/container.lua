local containers = require("models.containers")
local util = require("lapis.util")

local container_c = {}

container_c.GET = function(req, res, go)
	local db_container_entry = containers:find(req.params.container_id)

	res.body = util.to_json({container = db_container_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return container_c
