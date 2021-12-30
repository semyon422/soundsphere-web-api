local Leaderboards = require("models.leaderboards")
local Users = require("models.users")
local Community_leaderboards = require("models.community_leaderboards")
local Inputmodes = require("enums.inputmodes")
local db_search = require("util.db_search")
local db_where = require("util.db_where")
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
	{"inputmodes", type = "boolean", optional = true},
	{"top_user", type = "boolean", optional = true},
}
leaderboards_c.GET = function(request)
	local params = request.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local relations = {}
	if params.inputmodes then
		table.insert(relations, "leaderboard_inputmodes")
	elseif params.top_user then
		table.insert(relations, "top_user")
	end

	local clause = params.search and db_search(Leaderboards.db, params.search, "name")
	local paginator = Leaderboards:paginated(
		db_where(clause), "order by id asc",
		{
			per_page = per_page,
			prepare_results = function(entries)
				preload(entries, relations)
				return entries
			end
		}
	)
	local leaderboards = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	for _, leaderboard in ipairs(leaderboards) do
		if params.top_user then
			leaderboard.top_user = leaderboard.top_user:to_name()
		end
		if params.inputmodes then
			leaderboard.inputmodes = Inputmodes:entries_to_list(leaderboard.leaderboard_inputmodes)
			leaderboard.leaderboard_inputmodes = nil
		end
	end

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
leaderboards_c.POST = function(request)
	local params = request.params
	local leaderboard = Leaderboards:create({
		name = params.leaderboard.name or "Leaderboard",
		description = params.leaderboard.description,
		banner = params.leaderboard.banner,
	})

	Community_leaderboards:create({
		community_id = params.community_id,
		leaderboard_id = leaderboard.id,
		is_owner = true,
		sender_id = request.session.user_id,
		accepted = true,
		created_at = os.time(),
		message = "",
	})

	leaderboard_c.update_inputmodes(leaderboard.id, params.leaderboard.inputmodes)
	leaderboard_c.update_difftables(leaderboard.id, params.leaderboard.difftables)
	leaderboard_c.update_requirements(leaderboard.id, params.leaderboard.requirements)

	return {status = 201, redirect_to = request:url_for(leaderboard)}
end

return leaderboards_c
