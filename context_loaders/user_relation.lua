local User_relations = require("models.user_relations")

return function(self)
	if self.context.user_relation then return true end
	local user_relation_id = self.params.user_relation_id
	local user_id = self.params.user_id
	if user_relation_id and user_id then
		self.context.user_relation = User_relations:find({
			id = user_relation_id,
			user_id = user_id,
		})
	end
	return self.context.user_relation
end
