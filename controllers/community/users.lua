local Community_users = require("models.community_users")
local Users = require("models.users")
local Joined_query = require("util.joined_query")
local Roles = require("enums.roles")
local Controller = require("Controller")
local preload = require("lapis.db.model").preload
local community_user_c = require("controllers.community.user")
local util = require("util")

local community_users_c = Controller:new()

community_users_c.path = "/communities/:community_id[%d]/users"
community_users_c.methods = {"GET", "PATCH"}

community_users_c.get_invitations = function(self)
	local params = self.params

	local accepted = true
	local invitation = true
	if params.invitations then
		invitation = true
		accepted = false
	elseif params.requests then
		invitation = false
		accepted = false
	end
	if params.invitations and params.requests then
		invitation = nil
	end

	local db = Community_users.db

	local jq = Joined_query:new(db)
	jq:select("cu")
	jq:select("inner join users u on cu.user_id = u.id")
	jq:where("cu.accepted = ?", accepted)
	if invitation ~= nil then
		jq:where("cu.invitation = ?", invitation)
	end
	jq:where("cu.community_id = ?", params.community_id)
	jq:where("not u.is_banned")
	jq:fields("cu.*")

	jq:orders("cu.created_at desc")

	local query, options = jq:concat()

    local community_users = Community_users:select(query, options)

	return community_users, query
end

community_users_c.get_users = function(self)
	local params = self.params
	local db = Community_users.db

	local jq = Joined_query:new(db)
	jq:select("cu")
	jq:where("cu.accepted = ?", true)
	jq:where("cu.community_id = ?", params.community_id)
	jq:fields("cu.*")

	if params.leaderboard_id then
		jq:select("inner join leaderboard_users lu on cu.user_id = lu.user_id")
		jq:where("lu.active = ?", true)
		jq:where("lu.leaderboard_id = ?", params.leaderboard_id)
		jq:fields("lu.total_rating", "lu.scores_count", "lu.latest_score_submitted_at")
		jq:orders("lu.total_rating desc")
	end
	if params.user_id then
		jq:where("cu.user_id = ?", params.user_id)
	end
	if params.staff then
		jq:where({role = db.list(Roles.staff_roles)})
	end
	jq:select("inner join users u on cu.user_id = u.id")
	jq:where("not u.is_banned")
	if params.search then
		jq:where(util.db_search(db, params.search, "u.name"))
	end

	jq:orders("cu.user_id asc")

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local query, options = jq:concat()
	options.per_page = per_page

	local paginator = Community_users:paginated(query, options)
	local community_users = paginator:get_page(page_num)

	for i, community_user in ipairs(community_users) do
		community_user.rank = (page_num - 1) * per_page + i
		community_user.latest_score_submitted_at = tonumber(community_user.latest_score_submitted_at)
	end

	return community_users, query
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
		if community_user_c:check_access(self, "PATCH") then
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
	{"leaderboard_id", type = "number", optional = true, default = ""},
	{"user_id", type = "number", optional = true, default = ""},
}
util.add_belongs_to_validations(Community_users.relations, community_users_c.validations.GET)
util.add_has_many_validations(Users.relations, community_users_c.validations.GET)
community_users_c.GET = function(self)
	local params = self.params

	local community_users, filtered_clause
	if params.invitations or params.requests then
		community_users, filtered_clause = community_users_c.get_invitations(self)
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
	util.relatives_preload_field(community_users, "user", Users, params)
	util.recursive_to_name(community_users)

	-- don't set user for PUT method, first user will be used
	util.get_methods_for_objects(
		self,
		community_users,
		require("controllers.community.user"),
		"community_user",
		function(params, community_user)
			params.user_id = community_user.user_id
		end
	)

	return {json = {
		total = tonumber(Community_users:count(total_clause)),
		filtered = tonumber(util.db_count(Community_users, filtered_clause)),
		community_users = community_users,
	}}
end

community_users_c.context.PATCH = {"request_session", "session_user", "user_communities"}
community_users_c.policies.PATCH = {
	{"authed", {community_role = "creator"}},
	{"authed", {community_role = "admin"}},
}
community_users_c.validations.PATCH = {
	{"community_users", type = "table", param_type = "body"}
}
community_users_c.PATCH = function(self)
	local params = self.params

	local community_users = community_users_c.update_users(self, params.community_users)
	util.recursive_to_name(community_users)

	return {json = {community_users = community_users}}
end

return community_users_c
