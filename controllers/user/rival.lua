local User_relations = require("models.user_relations")
local Controller = require("Controller")

local user_rival_c = Controller:new()

user_rival_c.path = "/users/:user_id[%d]/rivals/:rival_id[%d]"
user_rival_c.methods = {"PUT", "DELETE"}

user_rival_c.policies.PUT = {{"permit"}}
user_rival_c.PUT = function(request)
	local params = request.params
	User_relations:relate("rival", params.user_id, params.rival_id)

	return 200, {}
end

user_rival_c.policies.DELETE = {{"permit"}}
user_rival_c.DELETE = function(request)
	local params = request.params
	User_relations:unrelate("rival", params.user_id, params.rival_id)

	return 200, {}
end

return user_rival_c
