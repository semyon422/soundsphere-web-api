local User_relations = require("models.user_relations")
local Controller = require("Controller")

local user_rival_c = Controller:new()

user_rival_c.path = "/users/:user_id/rivals/:rival_id"
user_rival_c.methods = {"PUT", "DELETE"}
user_rival_c.context = {}
user_rival_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
}

user_rival_c.PUT = function(request)
	local params = request.params
	User_relations:relate("rival", params.user_id, params.rival_id)

	return 200, {}
end

user_rival_c.DELETE = function(request)
	local params = request.params
	User_relations:unrelate("rival", params.user_id, params.rival_id)

	return 200, {}
end

return user_rival_c
