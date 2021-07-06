local Community_users = require("models.community_users")

local community_users_c = {}

community_users_c.PUT = function(params)
    local community_user = {
        community_id = params.community_id,
        user_id = params.user_id,
    }
    community_user = Community_users:find(community_user)
    if not community_user then
        Community_users:create(community_user)
    end

	return 200, {community_user = community_user}
end

community_users_c.DELETE = function(params)
    local community_user = {
        community_id = params.community_id,
        user_id = params.user_id,
    }
    community_user = Community_users:find(community_user)
    if community_user then
        community_user:delete()
    end

	return 200, {}
end

return community_users_c
