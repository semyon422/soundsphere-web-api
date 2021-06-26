local roles = require("models.roles")
local util = require("lapis.util")

local role_c = {}

role_c.GET = function(req, res, go)
	local db_role_entry = roles:find(req.params.role_id)

	res.body = util.to_json({role = db_role_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return role_c
