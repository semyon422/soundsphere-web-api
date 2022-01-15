local Leaderboards = require("models.leaderboards")
local Leaderboard_users = require("models.leaderboard_users")
local Community_leaderboards = require("models.community_leaderboards")
local util = require("util")
local preload = require("lapis.db.model").preload
local leaderboard_c = require("controllers.leaderboard")
local Controller = require("Controller")
local Difficulty_calculators = require("enums.difficulty_calculators")
local Rating_calculators = require("enums.rating_calculators")
local Combiners = require("enums.combiners")

local leaderboards_c = Controller:new()

leaderboards_c.path = "/leaderboards"
leaderboards_c.methods = {"GET", "POST"}

leaderboards_c.policies.GET = {{"permit"}}
leaderboards_c.validations.GET = {
	require("validations.per_page"),
	require("validations.page_num"),
	require("validations.search"),
	{"hide_joined", type = "boolean", optional = true},
}
util.add_belongs_to_validations(Leaderboards.relations, leaderboards_c.validations.GET)
util.add_has_many_validations(Leaderboards.relations, leaderboards_c.validations.GET)
leaderboards_c.GET = function(self)
	local params = self.params
	local per_page = params.per_page or 10
	local page_num = params.page_num or 1

	local db = Leaderboards.db
	local search_clause = params.search and util.db_search(db, params.search, "name")

	local joined_clause
	local joined_leaderboard_ids = {}
	local joined_leaderboard_ids_map = {}
	if self.session.user_id then
		local leaderboard_users = Leaderboard_users:find_all({self.session.user_id}, {
			key = "user_id",
			fields = "leaderboard_id"
		})
		for _, leaderboard_user in ipairs(leaderboard_users) do
			local id = leaderboard_user.leaderboard_id
			table.insert(joined_leaderboard_ids, id)
			joined_leaderboard_ids_map[id] = true
		end
		if params.hide_joined and #joined_leaderboard_ids > 0 then
			joined_clause = db.encode_clause({
				id = db.list(joined_leaderboard_ids)
			}):gsub("IN", "NOT IN")
		end
	end

	local clause = util.db_and(joined_clause, search_clause)
	local paginator = Leaderboards:paginated(
		util.db_where(clause) .. " order by id asc",
		{
			per_page = per_page,
		}
	)
	local leaderboards = paginator:get_page(page_num)
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
	{"community_id", exists = true, type = "number", range = {1}},
	{"leaderboard", exists = true, type = "table", param_type = "body", validations = {
		{"name", exists = true, type = "string"},
		{"description", exists = true, type = "string"},
		{"banner", exists = true, type = "string"},
		{"difficulty_calculator", type = "string", one_of = Difficulty_calculators.list},
		{"rating_calculator", type = "string", one_of = Rating_calculators.list},
		{"scores_combiner", type = "string", one_of = Combiners.list},
		{"communities_combiner", type = "string", one_of = Combiners.list},
		{"difficulty_calculator_config", exists = true, type = "number", default = 0},
		{"rating_calculator_config", exists = true, type = "number", default = 0},
		{"scores_combiner_count", exists = true, type = "number", default = 20},
		{"communities_combiner_count", exists = true, type = "number", default = 100},
	}}
}
leaderboards_c.POST = function(self)
	local params = self.params
	local leaderboard = Leaderboards:create({
		name = params.leaderboard.name or "Leaderboard",
		description = params.leaderboard.description,
		banner = params.leaderboard.banner,
		difficulty_calculator = Difficulty_calculators:for_db(params.leaderboard.difficulty_calculator),
		rating_calculator = Rating_calculators:for_db(params.leaderboard.rating_calculator),
		scores_combiner = Combiners:for_db(params.leaderboard.scores_combiner),
		communities_combiner = Combiners:for_db(params.leaderboard.communities_combiner),
		difficulty_calculator_config = params.leaderboard.difficulty_calculator_config,
		rating_calculator_config = params.leaderboard.rating_calculator_config,
		scores_combiner_count = params.leaderboard.scores_combiner_count,
		communities_combiner_count = params.leaderboard.communities_combiner_count,
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
