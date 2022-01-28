local User_relations = require("models.user_relations")
local Controller = require("Controller")

local user_relation_c = Controller:new()

user_relation_c.path = "/users/:user_id[%d]/relations/:user_relation_id[%d]"
user_relation_c.methods = {"GET", "DELETE"}

user_relation_c.context.GET = {"user_relation", "request_session"}
user_relation_c.policies.GET = {{"authed"}}
user_relation_c.GET = function(self)
	return {json = {user_relation = self.context.user_relation:to_name()}}
end

user_relation_c.context.DELETE = {"user_relation", "request_session"}
user_relation_c.policies.DELETE = {{"authed"}}
user_relation_c.DELETE = function(self)
	local user_relation = self.context.user_relation
	user_relation:delete()

	local reverse_user_relation = User_relations:find({
		relationtype = user_relation.relationtype,
		user_id = user_relation.relative_user_id,
		relative_user_id = user_relation.user_id,
	})

	if reverse_user_relation then
		reverse_user_relation.mutual = false
		reverse_user_relation:update("mutual")
	end

	return {status = 204}
end

return user_relation_c
