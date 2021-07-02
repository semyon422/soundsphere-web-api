local community_users = require("models.community_users")

local community_users_c = {}

community_users_c.PUT = function(params)
    local entry = {
        community_id = params.community_id,
        user_id = params.user_id,
    }
    local community_user = community_users:find(entry)
    if not community_user then
        community_users:create(entry)
    end

	return 200, {community_user = entry}
end

community_users_c.DELETE = function(params)
    local entry = {
        community_id = params.community_id,
        user_id = params.user_id,
    }
    local community_user = community_users:find(entry)
    if community_user then
        community_user:delete()
    end

	return 200, params
end

return community_users_c
