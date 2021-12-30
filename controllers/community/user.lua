local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local Controller = require("Controller")

local community_user_c = Controller:new()

community_user_c.path = "/communities/:community_id[%d]/users/:user_id[%d]"
community_user_c.methods = {"PUT", "DELETE", "GET", "PATCH"}

community_user_c.context.PUT = {"community_user", "request_session"}
community_user_c.policies.PUT = {{"authenticated"}}
community_user_c.validations.PUT = {
	{"invitation", type = "boolean", optional = true},
	{"message", exists = true, type = "string", optional = true},
}
community_user_c.PUT = function(self)
	local params = self.params
	local community_user = self.context.community_user

	if not community_user then
		community_user = {
			community_id = params.community_id,
			user_id = params.user_id,
			invitation = params.invitation,
			sender_id = self.session.user_id,
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

	return {}
end

community_user_c.context.DELETE = {"community_user", "request_session"}
community_user_c.policies.DELETE = {{"authenticated", "context_loaded"}}
community_user_c.DELETE = function(self)
	local community_user = self.context.community_user
    community_user:delete()

	return {status = 204}
end

community_user_c.context.GET = {"community_user"}
community_user_c.policies.GET = {{"context_loaded"}}
community_user_c.GET = function(self)
	local community_user = self.context.community_user
	community_user.role = Roles:to_name(community_user.role)

	return {json = {community_user = community_user}}
end

community_user_c.context.PATCH = {"community_user", "request_session"}
community_user_c.policies.PATCH = {{"authenticated", "context_loaded"}}
community_user_c.validations.PATCH = {
	{"role", exists = true, type = "string", one_of = Roles.list},
}
community_user_c.PATCH = function(self)
	local params = self.params
	local community_user = self.context.community_user
	Community_users:set_role(community_user, params.role, true)
	community_user.role = Roles:to_name(community_user.role)

	return {json = {community_user = community_user}}
end

return community_user_c
