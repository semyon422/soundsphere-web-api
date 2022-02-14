local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Community_changes = require("models.community_changes")
local Roles = require("enums.roles")
local Controller = require("Controller")
local util = require("util")

local community_user_c = Controller:new()

community_user_c.path = "/communities/:community_id[%d]/users/:user_id[%d]"
community_user_c.methods = {"GET", "PUT", "DELETE", "PATCH"}

community_user_c.context.PUT = {
	{"community_user", optional = true},
	"community",
	"request_session",
	"session_user",
	"user_communities",
}
community_user_c.policies.PUT = {
	{"authed", "not_user_profile", "community_user_invitation"},
}
community_user_c.validations.PUT = {
	{"message", type = "string", optional = true},
}
community_user_c.PUT = function(self)
	local params = self.params
	local community_user = self.context.community_user

	if not community_user then
		local staff_user_id = self.session.user_id
		community_user = {
			community_id = params.community_id,
			user_id = params.user_id,
			invitation = true,
			staff_user_id = staff_user_id,
			created_at = os.time(),
			message = params.message or "",
			accepted = false,
		}
		Community_users:set_role(community_user, "user")
		community_user = Community_users:create(community_user)
		Community_changes:add_change(
			staff_user_id,
			params.community_id,
			"invite",
			community_user:get_user()
		)
		return {status = 201, redirect_to = self:url_for(community_user)}
	elseif not community_user.accepted and not community_user.invitation then
		community_user.staff_user_id = self.session.user_id
		community_user.accepted = true
		community_user:update("accepted", "staff_user_id")
		Community_changes:add_change(
			community_user.staff_user_id,
			params.community_id,
			"accept",
			community_user:get_user()
		)
		return {status = 201, redirect_to = self:url_for(community_user)}
	end

	return {status = 204}
end

community_user_c.context.DELETE = {"community_user", "request_session", "session_user", "user_communities"}
community_user_c.policies.DELETE = {
	{"authed", "user_profile", "community_user_leave"},
	{"authed", "not_user_profile", "community_user_kick"},
	{"authed", "not_user_profile", "community_user_reject"},
}
community_user_c.DELETE = function(self)
	local community_user = self.context.community_user

    community_user:delete()
	Community_changes:add_change(
		self.context.session_user.id,
		self.params.community_id,
		"kick",
		self.context.user
	)

	return {status = 204}
end

community_user_c.context.GET = {"community_user"}
community_user_c.policies.GET = {{"permit"}}
community_user_c.validations.GET = util.add_belongs_to_validations(Community_users.relations)
community_user_c.GET = function(self)
	local community_user = self.context.community_user

	util.get_relatives(community_user, self.params, true)

	return {json = {community_user = community_user:to_name()}}
end

community_user_c.context.PATCH = {"community_user", "request_session", "session_user", "user_communities"}
community_user_c.policies.PATCH = {
	{"authed", "not_user_profile", "community_user_change_role", {not_params = "transfer_ownership"}},
	{"authed", "not_user_profile", "community_user_change_role", {community_role = "creator"}},
}
community_user_c.validations.PATCH = {
	{"role", type = "string", one_of = Roles.list},
	{"transfer_ownership", type = "boolean"},
}
community_user_c.PATCH = function(self)
	local params = self.params
	local community_user = self.context.community_user

	if params.transfer_ownership then
		Community_users:set_role(community_user, "creator", true)
		Community_users:set_role(Community_users:find({user_id = self.session.user_id}), "admin", true)
		Community_changes:add_change(
			self.context.session_user.id,
			params.community_id,
			"transfer_ownership",
			community_user:get_user()
		)
		return {json = {message = "Success"}}
	end

	Community_users:set_role(community_user, self.params.role, true)
	Community_changes:add_change(
		self.context.session_user.id,
		params.community_id,
		"update",
		community_user:get_user()
	)

	return {json = {community_user = community_user:to_name()}}
end

return community_user_c
