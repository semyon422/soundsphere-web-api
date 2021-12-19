local Community_users = require("models.community_users")
local Users = require("models.users")
local Roles = require("enums.roles")
local db_search = require("util.db_search")
local db_where = require("util.db_where")
local db_and = require("util.db_and")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload

local community_users_c = Controller:new()

community_users_c.path = "/communities/:community_id/users"
community_users_c.methods = {"GET"}
community_users_c.context = {}
community_users_c.policies = {
	GET = require("policies.public"),
}

community_users_c.get_invitations = function(request, invitation)
	local params = request.params

	local where = {
		community_id = params.community_id,
		accepted = false,
		invitation = invitation,
	}

	local clause = Community_users.db.encode_clause(where)
    local community_users = Community_users:select("where " .. clause .. " order by id asc")
	preload(community_users, "sender")

	return community_users, clause
end

local staff_roles = {}
for _, role in ipairs({"creator", "admin", "moderator"}) do
	table.insert(staff_roles, Roles:for_db(role))
end
community_users_c.get_staff = function(request)
	local params = request.params

	local db = Community_users.db
	local where = {
		community_id = params.community_id,
		accepted = true,
		role = db.list(staff_roles)
	}

	local clause = db.encode_clause(where)
    local community_users = Community_users:select("where " .. clause .. " order by id asc")

	return community_users, clause
end

community_users_c.get_users = function(request)
	local params = request.params

	local where = {
		community_id = params.community_id,
		accepted = true,
	}
	
	local db = Community_users.db
	local clause = db.encode_clause(where)

	local per_page = tonumber(params.per_page) or 10
	local page_num = tonumber(params.page_num) or 1

	local paginator
	if not params.search then
		paginator = Community_users:paginated(
			"where " .. clause .. " order by id asc",
			{
				per_page = per_page,
				page_num = page_num
			}
		)
	else
		paginator = Community_users:paginated(
			[[cu inner join users u on cu.user_id = u.id
			where cu.community_id = ? and accepted = true and (]] ..
			db_search(db, params.search, "name") ..
			[[) order by user_id asc]],
			params.community_id,
			{
				per_page = per_page,
				page_num = page_num,
				fields = "cu.*"
			}
		)
	end
	local community_users = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	return community_users
end

community_users_c.GET = function(request)
	local params = request.params

	local community_users, filtered_clause
	if params.invitations then
		community_users, filtered_clause = community_users_c.get_invitations(request, true)
	elseif params.requests then
		community_users, filtered_clause = community_users_c.get_invitations(request, false)
	elseif params.staff then
		community_users, filtered_clause = community_users_c.get_staff(request)
	else
		community_users = community_users_c.get_users(request)
	end
	preload(community_users, "user")

	local users = {}
	for _, community_user in ipairs(community_users) do
		local user = Users:safe_copy(community_user.user)
		user.community_user = community_user
		community_user.user = nil
		community_user.role = Roles:to_name(community_user.role)
		community_user.message = community_user.message
		community_user.created_at = community_user.created_at
		if community_user.sender then
			community_user.sender = Users:safe_copy(community_user.sender)
		end
		table.insert(users, user)
	end

	local db = Community_users.db
	local total_clause = db.encode_clause({
		community_id = params.community_id,
		accepted = true,
	})

	return 200, {
		total = Community_users:count(total_clause),
		filtered = Community_users:count(filtered_clause or total_clause),
		users = users,
	}
end

return community_users_c
