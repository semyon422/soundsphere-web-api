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
		where.invitations = true
		where.accepted = false
	elseif params.requests then
		where.requests = true
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

	preload(community_users, "user")

	local users = {}
	for _, community_user in ipairs(community_users) do
		local user = Users:safe_copy(community_user.user)
		user.role = Roles:to_name(community_user.role)
		table.insert(users, user)
	end

	return 200, {
		total = Community_users:count(clause),
		filtered = #community_users,
		users = users
	}
end

return community_users_c
