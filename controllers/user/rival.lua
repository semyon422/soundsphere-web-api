local User_relations = require("models.user_relations")
local Controller = require("Controller")

local user_rival_c = Controller:new()

user_rival_c.path = "/users/:user_id[%d]/rivals/:rival_id[%d]"
user_rival_c.methods = {"GET", "PUT", "DELETE"}

user_rival_c.context.GET = {"request_session"}
user_rival_c.policies.GET = {{"authenticated"}}
user_rival_c.GET = function(self)
	local params = self.params

	local user_relations = User_relations:find({
		relationtype = User_relations.types:for_db("rival"),
		user_id = params.user_id,
		relative_user_id = params.rival_id,
	})

	return {json = {user_relations = user_relations}}
end

user_rival_c.context.PUT = {"request_session"}
user_rival_c.policies.PUT = {{"authenticated"}}
user_rival_c.PUT = function(self)
	local params = self.params
	User_relations:relate("rival", params.user_id, params.rival_id)

	return {}
end

user_rival_c.context.DELETE = {"request_session"}
user_rival_c.policies.DELETE = {{"authenticated"}}
user_rival_c.DELETE = function(self)
	local params = self.params
	User_relations:unrelate("rival", params.user_id, params.rival_id)

	return {status = 204}
end

return user_rival_c
