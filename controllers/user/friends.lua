local User_relations = require("models.user_relations")
local Users = require("models.users")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local user_friends_c = Controller:new()

user_friends_c.path = "/users/:user_id[%d]/friends"
user_friends_c.methods = {"GET"}

user_friends_c.policies.GET = {{"permit"}}
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
		local friend = Users:safe_copy(user_relation.relative_user)
		friend.mutual = user_relation.mutual
		table.insert(friends, friend)
	end

	local count = User_relations:count()

	return 200, {
		total = count,
		filtered = count,
		friends = friends
	}
end

return user_friends_c
