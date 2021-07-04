local community_users = require("models.community_users")

local community_users_c = {}

community_users_c.GET = function(params)
    local sub_community_users = community_users:find_all({params.community_id}, "community_id")

	local count = community_users:count()

	return 200, {
		total = count,
		filtered = count,
		users = sub_community_users
	}
end

return community_users_c
