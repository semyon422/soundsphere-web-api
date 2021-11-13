local Community_users = require("models.community_users")

local community_user_c = {}

community_user_c.path = "/communities/:community_id/users/:user_id"
community_user_c.methods = {"PUT", "DELETE"}
community_user_c.context = {"community", "user", "user_roles"}
community_user_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
}

community_user_c.PUT = function(request)
	local params = request.params
    local community_user = {
        community_id = params.community_id,
        user_id = params.user_id,
    }
	local found_community_user = Community_users:find(community_user)

	if not found_community_user then
		if params.invitation then
			community_user.invitation = true
		end
        Community_users:create(community_user)
	else
		if found_community_user.invitation and not params.invitation or
			not found_community_user.invitation and params.invitation
		then
			found_community_user.accepted = true
			found_community_user:update("accepted")
		end
    end

	return 200, {}
end

community_user_c.DELETE = function(request)
	local params = request.params
    local community_user = Community_users:find({
        community_id = params.community_id,
        user_id = params.user_id,
    })
    if community_user then
        community_user:delete()
    end

	return 200, {}
end

return community_user_c
