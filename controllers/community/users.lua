local Community_users = require("models.community_users")
local Roles = require("enums.roles")
local db_search = require("util.db_search")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload
local community_user_c = require("controllers.community.user")
local util = require("util")

local community_users_c = Controller:new()

community_users_c.path = "/communities/:community_id[%d]/users"
community_users_c.methods = {"GET"}

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

community_users_c.get_staff = function(self)
	local params = self.params

	local db = Community_users.db
	local where = {
		community_id = params.community_id,
		accepted = true,
		role = db.list(Roles.staff_roles)
	}

	local clause = db.encode_clause(where)
    local community_users = Community_users:select("where " .. clause .. " order by id asc")

	return community_users, clause
end

community_users_c.get_users = function(self)
	local params = self.params

	local where = {
		community_id = params.community_id,
		accepted = true,
	}

	local db = Community_users.db
	local clause = db.encode_clause(where)

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local paginator
	if not params.search then
		paginator = Community_users:paginated(
			"where " .. clause .. " order by id asc",
			{
				per_page = per_page,
			}
		)
	else
		paginator = Community_users:paginated(
			"cu " ..
			"inner join users u on cu.user_id = u.id " ..
			"where cu.community_id = ? and accepted = true " ..
			"and (" .. db_search(db, params.search, "name") .. ") " ..
			"order by user_id asc",
			params.community_id,
			{
				per_page = per_page,
				fields = "cu.*"
			}
		)
	end
	local community_users = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	return community_users
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

	community_users = Community_users:find_all(community_user_ids)
	for _, community_user in ipairs(community_users) do
		self.context.community_user = community_user
		if community_user_c:check_access(self) then
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
util.add_belongs_to_validations(Community_users.relations, community_users_c.validations.GET)
community_users_c.GET = function(self)
	local params = self.params

	local community_users, filtered_clause
	if params.invitations then
		community_users, filtered_clause = community_users_c.get_invitations(self, true)
	elseif params.requests then
		community_users, filtered_clause = community_users_c.get_invitations(self, false)
	elseif params.staff then
		community_users, filtered_clause = community_users_c.get_staff(self)
	else
		community_users = community_users_c.get_users(self)
	end

	local db = Community_users.db
	local total_clause = db.encode_clause({
		community_id = params.community_id,
		accepted = true,
	})

	if params.no_data then
		return {json = {
			total = tonumber(Community_users:count(total_clause)),
			filtered = tonumber(Community_users:count(filtered_clause or total_clause)),
		}}
	end

	preload(community_users, util.get_relatives_preload(Community_users, params))
	util.recursive_to_name(community_users)

	return {json = {
		total = tonumber(Community_users:count(total_clause)),
		filtered = tonumber(Community_users:count(filtered_clause or total_clause)),
		community_users = community_users,
	}}
end

community_users_c.PATCH = function(self)
	local params = self.params

	community_users_c.update_users(self, params.community_users)

	return {}
end

return community_users_c
