local Communities = require("models.communities")
local Community_users = require("models.community_users")
local Inputmodes = require("enums.inputmodes")
local Roles = require("enums.roles")
local db_search = require("util.db_search")
local db_where = require("util.db_where")
local db_and = require("util.db_and")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local communities_c = Controller:new()

communities_c.path = "/communities"
communities_c.methods = {"GET", "POST"}

communities_c.policies.GET = {{"permit"}}
communities_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
	require("validations.search"),
	{"inputmodes", type = "boolean", optional = true},
	{"hide_joined", type = "boolean", optional = true},
}
communities_c.GET = function(request)
	local params = request.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local relations = {}
	if params.inputmodes then
		table.insert(relations, "difftable_inputmodes")
	end

	local db = Communities.db

	local search_clause = params.search and db_search(db, params.search, "name")

	local joined_clause
	local joined_community_ids = {}
	local joined_community_ids_map = {}
	if request.session.user_id then
		local community_users = Community_users:find_all({request.session.user_id}, {
			key = "user_id",
			fields = "community_id"
		})
		for _, community_user in ipairs(community_users) do
			local id = community_user.community_id
			table.insert(joined_community_ids, id)
			joined_community_ids_map[id] = true
		end
		if params.hide_joined == 1 and #joined_community_ids > 0 then
			joined_clause = db.encode_clause({
				id = db.list(joined_community_ids)
			}):gsub("IN", "NOT IN")
		end
	end

	local clause = db_and(joined_clause, search_clause)
	local paginator = Communities:paginated(
		db_where(clause), "order by id asc",
		{
			per_page = per_page,
			prepare_results = function(entries)
				preload(entries, relations)
				return entries
			end
		}
	)
	local communities = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	for _, community in ipairs(communities) do
		if params.inputmodes then
			community.inputmodes = Inputmodes:entries_to_list(community.community_inputmodes)
			community.community_inputmodes = nil
		end
		community.joined = joined_community_ids_map[community.id]
	end

	return {json = {
		total = tonumber(Communities:count()),
		filtered = tonumber(Communities:count(clause)),
		communities = communities,
	}}
end

communities_c.context.POST = {"request_session"}
communities_c.policies.POST = {{"authenticated"}}
communities_c.validations.POST = {
	{"community", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"alias", exists = true, type = "string"},
		{"link", exists = true, type = "string"},
		{"short_description", exists = true, type = "string"},
		{"description", exists = true, type = "string"},
		{"banner", exists = true, type = "string"},
		{"is_public", type = "boolean"},
	}}
}
communities_c.POST = function(request)
	local params = request.params
	local session = request.session

	local community = params.community
	community = Communities:create({
		name = community.name or "Community",
		alias = community.alias or "???",
		link = community.link,
		short_description = community.short_description,
		description = community.description,
		banner = community.banner,
		is_public = community.is_public,
	})

	Community_users:create({
		community_id = community.id,
		user_id = session.user_id,
		sender_id = session.user_id,
		role = Roles:for_db("creator"),
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	return {status = 201, redirect_to = request:url_for(community)}
end

return communities_c
