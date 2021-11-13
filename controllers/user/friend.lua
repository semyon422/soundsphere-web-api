local User_relations = require("models.user_relations")

local user_friend_c = {}

user_friend_c.path = "/users/:user_id/friends/:friend_id"
user_friend_c.methods = {"PUT", "DELETE"}
user_friend_c.context = {}
user_friend_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
}

user_friend_c.PUT = function(request)
	local params = request.params
	User_relations:relate("friend", params.user_id, params.friend_id)

	return 200, {}
end

user_friend_c.DELETE = function(request)
	local params = request.params
	User_relations:unrelate("friend", params.user_id, params.friend_id)

	return 200, {}
end

return user_friend_c
