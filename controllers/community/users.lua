local Community_users = require("models.community_users")
local Users = require("models.users")
local Roles = require("enums.roles")
local preload = require("lapis.db.model").preload

local community_users_c = {}

community_users_c.path = "/communities/:community_id/users"
community_users_c.methods = {"GET"}
community_users_c.context = {}
community_users_c.policies = {
	GET = require("policies.public"),
}

community_users_c.GET = function(request)
	local params = request.params

	local where = {accepted = true}
	where.community_id = params.community_id
	if params.invitations then
		where.invitation = true
		where.accepted = false
	elseif params.requests then
		where.invitation = false
		where.accepted = false
	end
	local clause = Community_users.db.encode_clause(where)

	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator = Community_users:paginated(
		"where " .. clause .. " order by id asc",
		{
			per_page = per_page,
			page_num = page_num
		}
	)
	local community_users = paginator:get_page(page_num)

	local relations = {"user"}
	if params.invitations then
		table.insert(relations, "sender")
	end
	preload(community_users, relations)

	local users = {}
	for _, community_user in ipairs(community_users) do
		local user = Users:safe_copy(community_user.user)
		user.role = Roles:to_name(community_user.role)
		user.message = community_user.message
		user.created_at = community_user.created_at
		user.sender = params.invitations and Users:safe_copy(community_user.sender)
		table.insert(users, user)
	end

	return 200, {
		total = Community_users:count(clause),
		filtered = #community_users,
		users = users
	}
end

return community_users_c
