local Difftables = require("models.difftables")
local Community_changes = require("models.community_changes")
local util = require("util")
local preload = require("lapis.db.model").preload
local Controller = require("Controller")

local difftables_c = Controller:new()

difftables_c.path = "/difftables"
difftables_c.methods = {"GET", "POST"}

difftables_c.policies.GET = {{"permit"}}
difftables_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
}
util.add_belongs_to_validations(Difftables.relations, difftables_c.validations.GET)
util.add_has_many_validations(Difftables.relations, difftables_c.validations.GET)
difftables_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local clause = params.search and util.db_search(Difftables.db, params.search, "name")
	local paginator = Difftables:paginated(
		util.db_where(clause) .. " order by id asc",
		{
			per_page = per_page,
		}
	)
	local difftables = paginator:get_page(page_num)
	preload(difftables, util.get_relatives_preload(Difftables, params))
	util.recursive_to_name(difftables)

	return {json = {
		total = tonumber(Difftables:count()),
		filtered = tonumber(Difftables:count(clause)),
		difftables = difftables,
	}}
end

local set_community_id = function(self)
	local params = self.params
	params.community_id = params.difftable and params.difftable.owner_community_id or 0
	return true
end

difftables_c.context.POST = {"request_session", "session_user", "user_communities", set_community_id}
difftables_c.display_policies.POST = {
	{"authed", "session_user_is_banned_deny"},
	{"authed", {any_community_role = "creator"}},
	{"authed", {any_community_role = "admin"}},
}
difftables_c.policies.POST = {
	{"authed", "session_user_is_banned_deny"},
	{"authed", {community_role = "creator"}},
	{"authed", {community_role = "admin"}},
}
difftables_c.validations.POST = {
	{"difftable", type = "table", param_type = "body", validations = {
		{"name", type = "string"},
		{"link", type = "string"},
		{"description", type = "string"},
		{"symbol", type = "string"},
		{"owner_community_id", type = "number"},
	}}
}
difftables_c.POST = function(self)
	local params = self.params
	local difftable = params.difftable

	if Difftables:find({name = difftable.name}) then
		return {status = 400, json = {message = "This name is already taken"}}
	end

	local difftables = Difftables:find_all({difftable.owner_community_id}, "owner_community_id")
	if #difftables >= 10 then
		return {status = 400, json = {message = "A community can have no more than 10 difftables"}}
	end

	difftable = Difftables:create({
		name = difftable.name or "Difficulty table",
		link = difftable.link,
		description = difftable.description,
		symbol = difftable.symbol,
		owner_community_id = difftable.owner_community_id,
		created_at = os.time(),
	})

	Community_changes:add_change(
		self.context.session_user.id,
		difftable.owner_community_id,
		"create",
		difftable
	)

	util.redirect_to(self, self:url_for(difftable))
	return {status = 201, json = {id = difftable.id}}
end

return difftables_c
