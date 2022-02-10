local User_relations = require("models.user_relations")
local new_context_loader = require("util.new_context_loader")

return new_context_loader("user_relation", function(self)
	local user_relation_id = self.params.user_relation_id
	local user_id = self.params.user_id
	if user_relation_id and user_id then
		return User_relations:find({
			id = user_relation_id,
			user_id = user_id,
		})
	end
end)
