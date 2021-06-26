local users = require("models.users")
local util = require("lapis.util")

local user_c = {}

user_c.GET = function(req, res, go)
	local db_user_entry = users:find(req.params.user_id)

	local user = {
        id = db_user_entry.id,
        name = db_user_entry.name,
        tag = db_user_entry.tag,
        latest_activity = db_user_entry.latest_activity,
    }

	res.body = util.to_json({user = user})
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end

return user_c
