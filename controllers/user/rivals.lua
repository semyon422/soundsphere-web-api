local User_relations = require("models.user_relations")
local preload = require("lapis.db.model").preload

local user_rivals_c = {}

user_rivals_c.GET = function(request)
	local params = request.params
	local rivals = {}
	local user_relations = User_relations:find_all(
		{params.user_id},
		"user_id",
		{where = {relationtype = User_relations.types.rival}}
	)
	preload(user_relations, "relative_user")
	for _, user_relation in ipairs(user_relations) do
		local rival = user_relation.relative_user
		table.insert(rivals, {
			id = rival.id,
			name = rival.name,
			tag = rival.tag,
			latest_activity = rival.latest_activity,
			mutual = user_relation.mutual
		})
	end

	local count = User_relations:count()

	return 200, {
		total = count,
		filtered = count,
		rivals = rivals
	}
end

return user_rivals_c
