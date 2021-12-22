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
}
leaderboards_c.GET = function(request)
	local params = request.params
	local per_page = params.per_page or 10
	local per_page = params.page_num or 1

	local clause = params.search and db_search(Leaderboards.db, params.search, "name")
	local paginator = Leaderboards:paginated(
		db_where(clause), "order by id asc",
		{
			per_page = per_page,
			prepare_results = function(entries)
				preload(entries, {"leaderboard_inputmodes", "top_user"})
				return entries
			end
		}
	)
	local leaderboards = params.get_all and paginator:get_all() or paginator:get_page(page_num)

	for _, leaderboard in ipairs(leaderboards) do
		leaderboard.top_user = Users:safe_copy(leaderboard.top_user)
		leaderboard.inputmodes = Inputmodes:entries_to_list(leaderboard.leaderboard_inputmodes)
		leaderboard.leaderboard_inputmodes = nil
	end

	return 200, {
		total = Leaderboards:count(),
		filtered = Leaderboards:count(clause),
		leaderboards = leaderboards
	}
end

leaderboards_c.context.POST = {"session"}
leaderboards_c.policies.POST = {{"authenticated"}}
leaderboards_c.validations.POST = {
	{"leaderboard", exists = true, type = "table", body = true, validations = {
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
	leaderboard_c.update_modifiers(leaderboard.id, params.leaderboard.modifiers)

	return 200, {leaderboard = leaderboard}
end

return leaderboards_c
