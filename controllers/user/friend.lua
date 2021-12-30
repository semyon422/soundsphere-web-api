local User_relations = require("models.user_relations")
local Controller = require("Controller")

local user_friend_c = Controller:new()

user_friend_c.path = "/users/:user_id[%d]/friends/:friend_id[%d]"
user_friend_c.methods = {"PUT", "DELETE"}

user_friend_c.context.PUT = {"request_session"}
user_friend_c.policies.PUT = {{"authenticated"}}
user_friend_c.PUT = function(self)
	local params = self.params
	User_relations:relate("friend", params.user_id, params.friend_id)

	return {}
end

user_friend_c.context.DELETE = {"request_session"}
user_friend_c.policies.DELETE = {{"authenticated"}}
user_friend_c.DELETE = function(self)
	local params = self.params
	User_relations:unrelate("friend", params.user_id, params.friend_id)

	return {status = 204}
end

return user_friend_c
