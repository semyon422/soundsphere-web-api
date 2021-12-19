local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local Controller = require("Controller")

local community_user_c = Controller:new()

community_user_c.path = "/communities/:community_id/users/:user_id"
community_user_c.methods = {"PUT", "DELETE", "GET", "PATCH"}
community_user_c.context = {"community", "user", "user_roles"}
community_user_c.policies = {
	PUT = require("policies.public"),
	DELETE = require("policies.public"),
	GET = require("policies.public"),
	PATCH = require("policies.public"),
}

community_user_c.PUT = function(request)
	local params = request.params

    local new_community_user = {
        community_id = params.community_id,
        user_id = params.user_id,
    }
	local community_user = Community_users:find(new_community_user)
	local community = Communities:find(params.community_id)

	if not community_user then
		if params.invitation then
			new_community_user.invitation = true
		end
		new_community_user.sender_id = request.session.user_id
		new_community_user.created_at = os.time()
		new_community_user.message = params.message or ""
		Community_users:set_role(new_community_user, community.is_public and "user" or "guest")
        Community_users:create(new_community_user)
	else
		if community_user.invitation and not params.invitation or
			not community_user.invitation and params.invitation
		then
			community_user.accepted = true
			Community_users:set_role(community_user, "user")
			community_user:update("accepted", "role")
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

community_user_c.GET = function(request)
	local params = request.params
    local community_user = Community_users:find({
        community_id = params.community_id,
        user_id = params.user_id,
    })
	if community_user then
		community_user.role = Roles:to_name(community_user.role)
	end

	return 200, {community_user = community_user}
end

community_user_c.PATCH = function(request)
	local params = request.params
    local community_user = Community_users:find({
        community_id = params.community_id,
        user_id = params.user_id,
    })
    if community_user then
		Community_users:set_role(community_user, params.role, true)
		community_user.role = Roles:to_name(community_user.role)
    end

	return 200, {community_user = community_user}
end

return community_user_c
