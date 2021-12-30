local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local user_communities_c = Controller:new()

user_communities_c.path = "/users/:user_id[%d]/communities"
user_communities_c.methods = {"GET"}

user_communities_c.policies.GET = {{"permit"}}
user_communities_c.validations.GET = {
	{"invitations", type = "boolean", optional = true},
	{"requests", type = "boolean", optional = true},
	{"is_admin", type = "boolean", optional = true},
}
user_communities_c.GET = function(self)
	local params = self.params
	local where = {accepted = true}
	if params.invitations then
		where.invitation = true
		where.accepted = false
	elseif params.requests then
		where.invitation = false
		where.accepted = false
	end

    local community_users = Community_users:find_all({params.user_id}, {
		key = "user_id",
		where = where
	})
	preload(community_users, "community")

    local communities = {}
	for _, community_user in ipairs(community_users) do
		local community = community_user.community
		local role = Roles:to_name(community_user.role)
		if not params.is_admin or role == "admin" or role == "creator" then
			community.role = role
			table.insert(communities, community)
		end
	end

	local count = tonumber(Community_users:count())

	return {json = {
		total = count,
		filtered = count,
		communities = communities
	}}
end

return user_communities_c
