local User_relations = require("models.user_relations")
local preload = require("lapis.db.model").preload

local user_friends_c = {}

user_friends_c.GET = function(request)
	local params = request.params
	local friends = {}
	local user_relations = User_relations:find_all(
		{params.user_id},
		"user_id",
		{where = {relationtype = User_relations.types.friend}}
	)
	preload(user_relations, "relative_user")
	for _, user_relation in ipairs(user_relations) do
		local friend = user_relation.relative_user
		table.insert(friends, {
			id = friend.id,
			name = friend.name,
			tag = friend.tag,
			latest_activity = friend.latest_activity,
			mutual = user_relation.mutual
		})
	end

	local count = User_relations:count()

	return 200, {
		total = count,
		filtered = count,
		friends = friends
	}
end

return user_friends_c
