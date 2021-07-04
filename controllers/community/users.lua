local community_users = require("models.community_users")
local preload = require("lapis.db.model").preload

local community_users_c = {}

community_users_c.GET = function(params)
    local sub_community_users = community_users:find_all({params.community_id}, "community_id")
	preload(sub_community_users, "user")

	local users = {}
	for _, community_user in ipairs(sub_community_users) do
		local user = community_user.user
		table.insert(users, {
			id = user.id,
			name = user.name,
			tag = user.tag,
			latest_activity = user.latest_activity,
		})
	end

	local count = community_users:count()

	return 200, {
		total = count,
		filtered = count,
		users = users
	}
end

return community_users_c
