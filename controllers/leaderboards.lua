local Leaderboards = require("models.leaderboards")
local Community_leaderboards = require("models.community_leaderboards")
local util = require("util")
local preload = require("lapis.db.model").preload
local leaderboard_c = require("controllers.leaderboard")
local Controller = require("Controller")

local leaderboards_c = Controller:new()

leaderboards_c.path = "/leaderboards"
leaderboards_c.methods = {"GET", "POST"}

leaderboards_c.policies.GET = {{"permit"}}
leaderboards_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.get_all"),
	require("validations.search"),
}
util.add_belongs_to_validations(Leaderboards.relations, leaderboards_c.validations.GET)
util.add_has_many_validations(Leaderboards.relations, leaderboards_c.validations.GET)
leaderboards_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local clause = params.search and util.db_search(Leaderboards.db, params.search, "name")
	local paginator = Leaderboards:paginated(
		util.db_where(clause), "order by id asc",
		{
			per_page = per_page,
		}
	)
	local leaderboards = params.get_all and paginator:get_all() or paginator:get_page(page_num)
	preload(leaderboards, util.get_relatives_preload(Leaderboards, params))
	util.recursive_to_name(leaderboards)

	return {json = {
		total = tonumber(Leaderboards:count()),
		filtered = tonumber(Leaderboards:count(clause)),
		leaderboards = leaderboards,
	}}
end

leaderboards_c.context.POST = {"request_session"}
leaderboards_c.policies.POST = {{"authenticated"}}
leaderboards_c.validations.POST = {
	{"leaderboard", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"description", exists = true, type = "string"},
		{"banner", exists = true, type = "string"},
	}}
}
leaderboards_c.POST = function(self)
	local params = self.params
	local leaderboard = Leaderboards:create({
		name = params.leaderboard.name or "Leaderboard",
		description = params.leaderboard.description,
		banner = params.leaderboard.banner,
	})

	Community_leaderboards:create({
		community_id = params.community_id,
		leaderboard_id = leaderboard.id,
		is_owner = true,
		sender_id = self.session.user_id,
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	leaderboard_c.update_inputmodes(leaderboard.id, params.leaderboard.inputmodes)
	leaderboard_c.update_difftables(leaderboard.id, params.leaderboard.difftables)
	leaderboard_c.update_requirements(leaderboard.id, params.leaderboard.requirements)

	return {status = 201, redirect_to = self:url_for(leaderboard)}
end

return leaderboards_c
