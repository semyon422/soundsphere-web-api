local User_relations = require("models.user_relations")

local user_friend_c = {}

user_friend_c.PUT = function(params)
	User_relations:relate("friend", params.user_id, params.friend_id)

	return 200, {}
end

user_friend_c.DELETE = function(params)
	User_relations:unrelate("friend", params.user_id, params.friend_id)

	return 200, {}
end

return user_friend_c
