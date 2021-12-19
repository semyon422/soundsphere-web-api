local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local Controller = require("Controller")

local community_user_c = Controller:new()

community_user_c.path = "/communities/:community_id[%d]/users/:user_id[%d]"
community_user_c.methods = {"PUT", "DELETE", "GET", "PATCH"}
community_user_c.context = {"community_user",
	PUT = {"session"},
	DELETE = {"session"},
	PATCH = {"session"},
}
community_user_c.policies = {
	PUT = {{
		rules = {"authenticated"}
	}},
	DELETE = {{
		rules = {"authenticated", "community_user"}
	}},
	GET = {{
		rules = {"community_user"}
	}},
	PATCH = {{
		rules = {"authenticated", "community_user"}
	}},
}

community_user_c.PUT = function(request)
	local params = request.params
	local community_user = request.context.community_user

	if not community_user then
		community_user = {
			community_id = params.community_id,
			user_id = params.user_id,
			invitation = params.invitation ~= nil,
			sender_id = request.session.user_id,
			created_at = os.time(),
			message = params.message or "",
		}
		local community = Communities:find(params.community_id)
		Community_users:set_role(community_user, community.is_public and "user" or "guest")
        Community_users:create(community_user)
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
	local community_user = request.context.community_user
    if community_user then
        community_user:delete()
    end

	return 200, {}
end

community_user_c.GET = function(request)
	local community_user = request.context.community_user
	if community_user then
		community_user.role = Roles:to_name(community_user.role)
	end

	return 200, {community_user = community_user}
end

community_user_c.PATCH = function(request)
	local params = request.params
	local community_user = request.context.community_user
    if community_user then
		Community_users:set_role(community_user, params.role, true)
		community_user.role = Roles:to_name(community_user.role)
    end

	return 200, {community_user = community_user}
end

return community_user_c
