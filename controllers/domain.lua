local domains = require("models.domains")
local util = require("lapis.util")

local domain_c = {}

domain_c.GET = function(req, res, go)
	local db_domain_entry = domains:find(req.params.domain_id)

	res.body = util.to_json({domain = db_domain_entry})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return domain_c
