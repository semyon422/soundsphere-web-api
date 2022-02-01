local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Inputmodes = require("enums.inputmodes")
local Roles = require("enums.roles")
local util = require("util")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local communities_c = Controller:new()

communities_c.path = "/communities"
communities_c.methods = {"GET", "POST"}

communities_c.policies.GET = {{"permit"}}
communities_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
	{"hide_joined", type = "boolean", optional = true},
}
util.add_belongs_to_validations(Communities.relations, communities_c.validations.GET)
util.add_has_many_validations(Communities.relations, communities_c.validations.GET)
communities_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local db = Communities.db
	local search_clause = params.search and util.db_search(db, params.search, "name")

	local joined_clause
	local joined_community_ids = {}
	local joined_community_ids_map = {}
	if self.session.user_id then
		local community_users = Community_users:find_all({self.session.user_id}, {
			key = "user_id",
			fields = "community_id"
		})
		for _, community_user in ipairs(community_users) do
			local id = community_user.community_id
			table.insert(joined_community_ids, id)
			joined_community_ids_map[id] = true
		end
		if params.hide_joined and #joined_community_ids > 0 then
			joined_clause = db.encode_clause({
				id = db.list(joined_community_ids)
			}):gsub("IN", "NOT IN")
		end
	end

	local clause = util.db_and(joined_clause, search_clause)
	local paginator = Communities:paginated(
		util.db_where(clause) .. " order by id asc",
		{
			per_page = per_page,
		}
	)
	local communities = paginator:get_page(page_num)
	preload(communities, util.get_relatives_preload(Communities, params))
	util.recursive_to_name(communities)

	for _, community in ipairs(communities) do
		community.joined = joined_community_ids_map[community.id]
	end

	return {json = {
		total = tonumber(Communities:count()),
		filtered = tonumber(Communities:count(clause)),
		communities = communities,
	}}
end

communities_c.context.POST = {"request_session", "session_user", "user_communities", "user_roles"}
communities_c.policies.POST = {
	{"authed", "session_user_is_banned_deny"},
	{"authed"},
}
communities_c.validations.POST = {
	{"community", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"alias", exists = true, type = "string"},
		{"link", exists = true, type = "string", optional = true},
		{"short_description", exists = true, type = "string", optional = true},
		{"description", exists = true, type = "string", optional = true},
		{"banner", exists = true, type = "string", optional = true},
		{"is_public", type = "boolean"},
	}}
}
communities_c.POST = function(self)
	local params = self.params
	local session = self.session

	local user = self.context.session_user
	local is_public = params.community.is_public
	if not user.roles.donator and not is_public then
		return {status = 400, json = {message = "Creation of private communities is available only to donators"}}
	end
	if #user.communities:select({role = "creator", is_public = is_public}) >= 1 then
		return {status = 400, json = {message = "You can create only one community of this type (public or private)"}}
	end
	if Communities:find({name = params.community.name}) then
		return {status = 400, json = {message = "This name is already taken"}}
	end
	if Communities:find({alias = params.community.alias}) then
		return {status = 400, json = {message = "This alias is already taken"}}
	end

	if not user.roles.donator then
		params.community.banner = ""
	end

	local community = params.community
	community = Communities:create({
		name = community.name,
		alias = community.alias,
		link = community.link,
		short_description = community.short_description,
		description = community.description,
		banner = community.banner,
		is_public = community.is_public,
	})

	Community_users:create({
		community_id = community.id,
		user_id = session.user_id,
		staff_user_id = session.user_id,
		role = Roles:for_db("creator"),
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	return {status = 201, json = {id = community.id, redirect_to = self:url_for(community)}}
end

return communities_c
