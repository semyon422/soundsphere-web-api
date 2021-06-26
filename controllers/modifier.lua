local modifiers = require("models.modifiers")
local util = require("lapis.util")

local modifier_c = {}

modifier_c.GET = function(req, res, go)
	local db_modifier_entry = modifiers:find(req.params.modifier_id)

	res.body = util.to_json({modifier = db_modifier_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return modifier_c
