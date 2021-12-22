local Community_users = require("models.community_users")
local Users = require("models.users")
local Roles = require("enums.roles")
local db_search = require("util.db_search")
local db_where = require("util.db_where")
local db_and = require("util.db_and")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload
local community_user_c = require("controllers.community.user")

local community_users_c = Controller:new()

community_users_c.path = "/communities/:community_id[%d]/users"
community_users_c.methods = {"GET"}

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

	local per_page = params.per_page or 10
	local per_page = params.page_num or 1

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

community_users_c.update_users = function(request, community_id, users)
	if not users then
		return
	end

	local community_user_ids = {}
	local community_users_map = {}
	for _, user in ipairs(users) do
		local community_user = user.community_user
		table.insert(community_user_ids, community_user.id)
		community_users_map[community_user.id] = community_user
		community_user.role = Roles:for_db(community_user.role)
	end

	if #community_user_ids == 0 then
		return
	end

	local community_users = Community_users:find_all(community_user_ids)
	for _, community_user in ipairs(community_users) do
		request.context.community_user = community_user
		if community_user_c:check_access(request) then
			local new_community_user = community_users_map[community_user.id]
			if community_user.role ~= new_community_user.role then
				community_user.role = new_community_user.role
				community_user:update("role")
			end
		end
	end
end

community_users_c.policies.GET = {{"permit"}}
community_users_c.validations.GET = {
	require("validations.no_data"),
	{"invitations", type = "boolean", optional = true},
	{"requests", type = "boolean", optional = true},
	{"staff", type = "boolean", optional = true},
}
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

	local db = Community_users.db
	local total_clause = db.encode_clause({
		community_id = params.community_id,
		accepted = true,
	})

	if params.no_data then
		return 200, {
			total = Community_users:count(total_clause),
			filtered = Community_users:count(filtered_clause or total_clause),
		}
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

	return 200, {
		total = Community_users:count(total_clause),
		filtered = Community_users:count(filtered_clause or total_clause),
		users = users,
	}
end

community_users_c.PATCH = function(request)
	local params = request.params

	community_users_c.update_users(request, params.community_id, params.users)

	return 200, {}
end

return community_users_c
