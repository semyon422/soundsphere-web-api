local User_relations = require("models.user_relations")

local user_rival_c = {}

user_rival_c.PUT = function(params)
	User_relations:relate("rival", params.user_id, params.rival_id)

	return 200, {}
end

user_rival_c.DELETE = function(params)
	User_relations:unrelate("rival", params.user_id, params.rival_id)

	return 200, {}
end

return user_rival_c
