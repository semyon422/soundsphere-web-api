local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local Controller = require("Controller")
local util = require("util")

local community_user_c = Controller:new()

community_user_c.path = "/communities/:community_id[%d]/users/:user_id[%d]"
community_user_c.methods = {"GET", "PUT", "DELETE", "PATCH"}

community_user_c.context.PUT = {
	{"community_user", optional = true},
	"request_session",
	"session_user",
	"user_communities",
}
community_user_c.policies.PUT = {
	{"authed", "community_user_request"},
	{"authed", "community_user_invitation"},
}
community_user_c.validations.PUT = {
	{"invitation", type = "boolean", optional = true},
	{"message", exists = true, type = "string", optional = true},
}
community_user_c.PUT = function(self)
	local params = self.params
	local community_user = self.context.community_user

	if not community_user then
		local community = Communities:find(params.community_id)
		local staff_user_id = 0
		if params.invitation then
			staff_user_id = self.session.user_id
		end
		community_user = {
			community_id = params.community_id,
			user_id = params.user_id,
			invitation = params.invitation,
			staff_user_id = staff_user_id,
			created_at = os.time(),
			message = params.message or "",
			accepted = community.is_public,
		}
		Community_users:set_role(community_user, "user")
		Community_users:create(community_user)
		return {status = 201}
	elseif not community_user.accepted then
		if community_user.invitation and not params.invitation or
			not community_user.invitation and params.invitation
		then
			if params.invitation then
				community_user.staff_user_id = self.session.user_id
			end
			community_user.accepted = true
			community_user:update("accepted", "staff_user_id")
			return {}
		end
	end

	return {status = 204}
end

community_user_c.context.DELETE = {"community_user", "request_session", "session_user", "user", "user_communities"}
community_user_c.policies.DELETE = {
	{"authed", "community_user_leave"},
	{"authed", "community_user_kick"},
}
community_user_c.DELETE = function(self)
    self.context.community_user:delete()
	return {status = 204}
end

community_user_c.context.GET = {"community_user"}
community_user_c.policies.GET = {{"context_loaded"}}
community_user_c.validations.GET = util.add_belongs_to_validations(Community_users.relations)
community_user_c.GET = function(self)
	local community_user = self.context.community_user

	util.get_relatives(community_user, self.params, true)

	return {json = {community_user = community_user:to_name()}}
end

community_user_c.context.PATCH = {"community_user", "request_session", "session_user", "user_communities"}
community_user_c.policies.PATCH = {
	{"authed", "community_user_change_role"},
}
community_user_c.validations.PATCH = {
	{"role", exists = true, type = "string", one_of = Roles.list},
}
community_user_c.PATCH = function(self)
	local community_user = self.context.community_user

	Community_users:set_role(community_user, self.params.role, true)

	return {json = {community_user = community_user:to_name()}}
end

return community_user_c
