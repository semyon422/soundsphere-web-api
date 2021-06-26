local input_modes = require("models.input_modes")
local util = require("lapis.util")

local input_mode_c = {}

input_mode_c.GET = function(req, res, go)
	local db_input_mode_entry = input_modes:find(req.params.input_mode_id)

	res.body = util.to_json({input_mode = db_input_mode_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return input_mode_c
