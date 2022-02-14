local Community_changes = require("models.community_changes")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")
local util = require("util")
local Joined_query = require("util.joined_query")

local community_changes_c = Controller:new()

community_changes_c.path = "/communities/:community_id[%d]/changes"
community_changes_c.methods = {"GET"}

community_changes_c.context.GET = {"request_session", "session_user", "user_communities"}
community_changes_c.policies.GET = {
	{"authed", {community_role = "moderator"}},
	{"authed", {community_role = "admin"}},
	{"authed", {community_role = "creator"}},
}
community_changes_c.validations.GET = {
	require("validations.no_data"),
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
	{"hide_own", type = "boolean", optional = true},
}
util.add_belongs_to_validations(Community_changes.relations, community_changes_c.validations.GET)
community_changes_c.GET = function(self)
	local params = self.params

	local user_id = self.session.user_id
	local db = Community_changes.db

	local jq = Joined_query:new(db)
	jq:select("cc")
	jq:where("cc.community_id = ?", params.community_id)
	if user_id and params.hide_own then
		jq:where("cc.user_id != ?", user_id)
	end
	if params.search then
		jq:select("inner join users u on cc.user_id = u.id")
		jq:where(util.db_search(db, params.search, "u.name"))
	end
	jq:orders("cc.created_at desc")
	jq:fields("cc.*")

	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local query, options = jq:concat()
	options.per_page = per_page

	local paginator = Community_changes:paginated(query, options)
	local community_changes = paginator:get_page(page_num)

	local count = tonumber(Community_changes:count("community_id = ?", params.community_id))
	if params.no_data then
		return {json = {
			total = count,
			filtered = tonumber(util.db_count(Community_changes, query)),
		}}
	end

	preload(community_changes, util.get_relatives_preload(Community_changes, params))
	util.recursive_to_name(community_changes)

	if user_id then
		for _, community_change in ipairs(community_changes) do
			community_change.is_own = community_change.user_id == user_id
		end
	end

	return {json = {
		total = count,
		filtered = tonumber(util.db_count(Community_changes, query)),
		community_changes = community_changes,
	}}
end

return community_changes_c
