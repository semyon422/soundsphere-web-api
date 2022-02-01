local Community_users = require("models.community_users")
local Communities = require("models.communities")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")
local community_user_c = require("controllers.community.user")

local user_community_c = Controller:new()

user_community_c.path = "/users/:user_id[%d]/communities/:community_id[%d]"
user_community_c.methods = {"PUT"}

user_community_c.context.PUT = {
	{"community_user", optional = true},
	"user",
	"community",
	"request_session",
	"session_user",
	"user_communities",
}
user_community_c.policies.PUT = {
	{"authed", "user_profile", "community_user_request"},
}
user_community_c.validations.PUT = {
	{"message", exists = true, type = "string", optional = true},
}
user_community_c.PUT = function(self)
	local params = self.params
	local community_user = self.context.community_user

	if not community_user then
		local community = self.context.community
		community_user = {
			community_id = params.community_id,
			user_id = params.user_id,
			invitation = false,
			staff_user_id = 0,
			created_at = os.time(),
			message = params.message or "",
			accepted = community.is_public,
		}
		Community_users:set_role(community_user, "user")
		community_user = Community_users:create(community_user)
		return {status = 201, json = {redirect_to = self:url_for(community_user)}}
	elseif not community_user.accepted and community_user.invitation then
		community_user.accepted = true
		community_user:update("accepted", "staff_user_id")
		return {status = 200, json = {redirect_to = self:url_for(community_user)}}
	end

	return {status = 204}
end

return user_community_c
