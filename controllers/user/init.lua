local users = require("models.users")
local util = require("lapis.util")

local user_c = {}

user_c.GET = function(params)
	local db_user_entry = users:find(params.user_id)

	local user = {
        id = db_user_entry.id,
        name = db_user_entry.name,
        tag = db_user_entry.tag,
        latest_activity = db_user_entry.latest_activity,
    }

	return 200, {user = user}
end

return user_c
