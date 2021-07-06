local Users = require("models.users")

local user_c = {}

user_c.GET = function(params)
	local user = Users:find(params.user_id)

	user = {
        id = user.id,
        name = user.name,
        tag = user.tag,
        latest_activity = user.latest_activity,
        description = user.description,
    }

	return 200, {user = user}
end

user_c.PATCH = function(params)
	local user = Users:find(params.user_id)

	user.name = params.user.name
	user.description = params.user.description

	user:update("name", "description")

	return 200, {user = user}
end

return user_c
