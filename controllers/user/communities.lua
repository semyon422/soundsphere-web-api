local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local preload = require("lapis.db.model").preload

local user_communities_c = {}

user_communities_c.path = "/users/:user_id/communities"
user_communities_c.methods = {"GET"}
user_communities_c.context = {}
user_communities_c.policies = {
	GET = require("policies.public"),
}

user_communities_c.GET = function(request)
	local params = request.params
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

	local count = Community_users:count()

	return 200, {
		total = count,
		filtered = count,
		communities = communities
	}
end

return user_communities_c
