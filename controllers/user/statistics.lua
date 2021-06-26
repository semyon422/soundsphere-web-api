local util = require("lapis.util")

local user_statistics_c = {}

user_statistics_c.GET = function(req, res, go)
	res.body = util.to_json({})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return user_statistics_c
