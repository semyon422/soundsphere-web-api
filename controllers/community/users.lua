local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload
local community_user_c = require("controllers.community.user")
local util = require("util")

local community_users_c = Controller:new()

community_users_c.path = "/communities/:community_id[%d]/users"
community_users_c.methods = {"GET", "PATCH"}

community_users_c.get_invitations = function(self, invitation)
	local params = self.params

	local where = {
		community_id = params.community_id,
		accepted = false,
		invitation = invitation,
	}

	local clause = Community_users.db.encode_clause(where)
    local community_users = Community_users:select("where " .. clause .. " order by id asc")

	return community_users, clause
end

community_users_c.get_users = function(self)
	local params = self.params
	local db = Community_users.db

	local clause_table = {"cu"}
	local where_table = {"cu.accepted = true", "cu.community_id = ?"}
	local fields = {"cu.*"}
	local orders = {}
	local opts = {params.community_id}

	if params.leaderboard_id then
		table.insert(clause_table, "inner join leaderboard_users lu on cu.user_id = lu.user_id")
		table.insert(fields, "lu.total_rating")
		table.insert(fields, "lu.scores_count")
		table.insert(orders, "lu.total_rating desc")
		table.insert(where_table, "lu.active = true")
		table.insert(where_table, "lu.leaderboard_id = ?")
		table.insert(opts, params.leaderboard_id)
	end
	if params.staff then
		table.insert(where_table, db.encode_clause({role = db.list(Roles.staff_roles)}))
	end
	if params.search then
		table.insert(clause_table, "inner join users u on cu.user_id = u.id")
		table.insert(where_table, util.db_search(db, params.search, "name"))
	end
	table.insert(orders, "cu.user_id asc")

	table.insert(clause_table, util.db_where(util.db_and(where_table)))
	table.insert(clause_table, "order by " .. table.concat(orders, ", "))

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1
	local clause = db.interpolate_query(
		table.concat(clause_table, " "),
		unpack(opts)
	)

	local paginator = Community_users:paginated(clause, {
		per_page = per_page,
		fields = table.concat(fields, ", "),
	})
	local community_users = paginator:get_page(page_num)

	for i, community_user in ipairs(community_users) do
		community_user.rank = (page_num - 1) * per_page + i
	end

	return community_users, clause
end

community_users_c.update_users = function(self, community_users)
	if not community_users then
		return
	end

	local community_user_ids = {}
	local community_users_map = {}
	for _, community_user in ipairs(community_users) do
		local id = tonumber(community_user.id)
		table.insert(community_user_ids, id)
		community_users_map[id] = community_user
		community_user.role = Roles:for_db(community_user.role)
	end

	if #community_user_ids == 0 then
		return
	end

	local updated_community_users = {}
	community_users = Community_users:find_all(community_user_ids)
	for _, community_user in ipairs(community_users) do
		self.context.community_user = community_user
		if community_user_c:check_access(self) then
			local new_community_user = community_users_map[community_user.id]
			if community_user.role ~= new_community_user.role then
				community_user.role = new_community_user.role
				community_user:update("role")
				table.insert(updated_community_users, community_user)
			end
		end
	end
	return updated_community_users
end

community_users_c.policies.GET = {{"permit"}}
community_users_c.validations.GET = {
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
	{"invitations", type = "boolean", optional = true},
	{"requests", type = "boolean", optional = true},
	{"staff", type = "boolean", optional = true},
	{"leaderboard_id", exists = true, type = "number", optional = true, default = ""},
}
util.add_belongs_to_validations(Community_users.relations, community_users_c.validations.GET)
community_users_c.GET = function(self)
	local params = self.params

	local community_users, filtered_clause
	if params.invitations then
		community_users, filtered_clause = community_users_c.get_invitations(self, true)
	elseif params.requests then
		community_users, filtered_clause = community_users_c.get_invitations(self, false)
	else
		community_users, filtered_clause = community_users_c.get_users(self)
	end

	local db = Community_users.db
	local total_clause = db.encode_clause({
		community_id = params.community_id,
		accepted = true,
	})

	if params.no_data then
		return {json = {
			total = tonumber(Community_users:count(total_clause)),
			filtered = tonumber(util.db_count(Community_users, filtered_clause)),
		}}
	end

	preload(community_users, util.get_relatives_preload(Community_users, params))
	util.recursive_to_name(community_users)

	return {json = {
		total = tonumber(Community_users:count(total_clause)),
		filtered = tonumber(util.db_count(Community_users, filtered_clause)),
		community_users = community_users,
	}}
end

community_users_c.context.PATCH = {"request_session", "session_user", "user_communities"}
community_users_c.policies.PATCH = {
	{"context_loaded", "authenticated", {community_role = "creator"}},
	{"context_loaded", "authenticated", {community_role = "admin"}},
}
community_users_c.validations.PATCH = {
	{"community_users", exists = true, type = "table", param_type = "body"}
}
community_users_c.PATCH = function(self)
	local params = self.params

	local community_users = community_users_c.update_users(self, params.community_users)
	util.recursive_to_name(community_users)

	return {json = {community_users = community_users}}
end

return community_users_c
