local community_users = require("models.community_users")

local community_users_c = {}

community_users_c.GET = function(params)
    local sub_community_users = community_users:find_all({params.community_id}, "community_id")

	return 200, {users = sub_community_users}
end

return community_users_c
