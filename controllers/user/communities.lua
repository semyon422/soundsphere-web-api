local Community_users = require("models.community_users")
local preload = require("lapis.db.model").preload

local user_communities_c = {}

user_communities_c.GET = function(params)
    local community_users = Community_users:find_all({params.user_id}, "user_id")
	preload(community_users, "community")

    local communities = {}
	for _, community_user in ipairs(community_users) do
        table.insert(communities, community_user.community)
	end

	local count = Community_users:count()

	return 200, {
		total = count,
		filtered = count,
		communities = communities
	}
end

return user_communities_c
