local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")

local user_communities_c = Controller:new()

user_communities_c.path = "/users/:user_id[%d]/communities"
user_communities_c.methods = {"GET"}

user_communities_c.policies.GET = {{"permit"}}
user_communities_c.validations.GET = {
	{"invitations", type = "boolean", optional = true},
	{"requests", type = "boolean", optional = true},
	{"is_admin", type = "boolean", optional = true},
}
user_communities_c.validations.GET = util.add_belongs_to_validations(Community_users.relations)
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

	if params.no_data then
		return {json = {
			total = #community_users,
			filtered = #community_users,
		}}
	end

	preload(community_users, util.get_relatives_preload(Community_users, params))
	util.recursive_to_name(community_users)

    local filtered_community_users = {}
	for _, community_user in ipairs(community_users) do
		local role = community_user.role
		if not params.is_admin or role == "admin" or role == "creator" then
			table.insert(filtered_community_users, community_user)
		end
	end

	return {json = {
		total = #community_users,
		filtered = #filtered_community_users,
		user_communities = filtered_community_users,
	}}
end

return user_communities_c
