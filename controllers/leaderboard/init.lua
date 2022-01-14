local Leaderboards = require("models.leaderboards")
local Leaderboard_inputmodes = require("models.leaderboard_inputmodes")
local Leaderboard_difftables = require("models.leaderboard_difftables")
local Inputmodes = require("enums.inputmodes")
local Difficulty_calculators = require("enums.difficulty_calculators")
local Rating_calculators = require("enums.rating_calculators")
local Combiners = require("enums.combiners")
local util = require("util")
local Controller = require("Controller")

local additions = {
	difftables = require("controllers.leaderboard.difftables"),
	communities = require("controllers.leaderboard.communities"),
	users = require("controllers.leaderboard.users"),
	inputmodes = require("controllers.leaderboard.inputmodes"),
	requirements = require("controllers.leaderboard.requirements"),
}

local leaderboard_c = Controller:new()

leaderboard_c.path = "/leaderboards/:leaderboard_id[%d]"
leaderboard_c.methods = {"GET", "PATCH", "DELETE"}

leaderboard_c.update_requirements = function(leaderboard_id, requirements)
	return additions.requirements.update_requirements(leaderboard_id, requirements)
end

leaderboard_c.update_inputmodes = function(leaderboard_id, inputmodes)
	if not inputmodes then
		return
	end

	local leaderboard_inputmodes = Leaderboard_inputmodes:find_all({leaderboard_id}, "leaderboard_id")

	local new_inputmodes, old_inputmodes = util.array_update(
		inputmodes,
		leaderboard_inputmodes,
		function(i) return Inputmodes:for_db(i) end,
		function(li) return li.inputmode end
	)

	local db = Leaderboard_inputmodes.db
	if #old_inputmodes > 0 then
		db.delete("leaderboard_inputmodes", {inputmode = db.list(old_inputmodes)})
	end
	for _, inputmode in ipairs(new_inputmodes) do
		db.insert("leaderboard_inputmodes", {
			leaderboard_id = leaderboard_id,
			inputmode = inputmode,
		})
	end
end

leaderboard_c.update_difftables = function(leaderboard_id, difftables)
	if not difftables then
		return
	end

	local leaderboard_difftables = Leaderboard_difftables:find_all({leaderboard_id}, "leaderboard_id")

	local new_difftable_ids, old_difftable_ids = util.array_update(
		difftables,
		leaderboard_difftables,
		function(d) return d.id end,
		function(ld) return ld.difftable_id end
	)

	local db = Leaderboard_difftables.db
	if #old_difftable_ids > 0 then
		db.delete("leaderboard_difftables", {difftable_id = db.list(old_difftable_ids)})
	end
	for _, difftable_id in ipairs(new_difftable_ids) do
		db.insert("leaderboard_difftables", {
			leaderboard_id = leaderboard_id,
			difftable_id = difftable_id,
		})
	end
end

leaderboard_c.context.GET = {"leaderboard"}
leaderboard_c.policies.GET = {{"context_loaded"}}
leaderboard_c.validations.GET = {}
util.add_additions_validations(additions, leaderboard_c.validations.GET)
util.add_belongs_to_validations(Leaderboards.relations, leaderboard_c.validations.GET)
leaderboard_c.GET = function(self)
	local params = self.params
	local leaderboard = self.context.leaderboard

	util.load_additions(self, leaderboard, additions)
	util.get_relatives(leaderboard, self.params, true)

	return {json = {leaderboard = leaderboard:to_name()}}
end

leaderboard_c.context.PATCH = {"leaderboard", "request_session"}
leaderboard_c.policies.PATCH = {{"context_loaded", "authenticated"}}
leaderboard_c.validations.PATCH = {
	{"leaderboard", type = "table", param_type = "body", validations = {
		{"name", type = "string"},
		{"description", type = "string"},
		{"banner", type = "string"},
		{"difficulty_calculator", type = "string", one_of = Difficulty_calculators.list},
		{"rating_calculator", type = "string", one_of = Rating_calculators.list},
		{"scores_combiner", type = "string", one_of = Combiners.list},
		{"communities_combiner", type = "string", one_of = Combiners.list},
		{"difficulty_calculator_config", exists = true, type = "number", default = 0},
		{"rating_calculator_config", exists = true, type = "number", default = 0},
		{"scores_combiner_count", exists = true, type = "number", default = 20},
		{"communities_combiner_count", exists = true, type = "number", default = 100},
	}},
}
leaderboard_c.PATCH = function(self)
	local params = self.params
	local leaderboard = self.context.leaderboard

	leaderboard.name = params.leaderboard.name
	leaderboard.description = params.leaderboard.description
	leaderboard.banner = params.leaderboard.banner
	leaderboard.difficulty_calculator = Difficulty_calculators:for_db(params.leaderboard.difficulty_calculator)
	leaderboard.rating_calculator = Rating_calculators:for_db(params.leaderboard.rating_calculator)
	leaderboard.scores_combiner = Combiners:for_db(params.leaderboard.scores_combiner)
	leaderboard.communities_combiner = Combiners:for_db(params.leaderboard.communities_combiner)
	leaderboard.difficulty_calculator_config = params.leaderboard.difficulty_calculator_config
	leaderboard.rating_calculator_config = params.leaderboard.rating_calculator_config
	leaderboard.scores_combiner_count = params.leaderboard.scores_combiner_count
	leaderboard.communities_combiner_count = params.leaderboard.communities_combiner_count
	leaderboard:update(
		"name",
		"description",
		"banner",
		"difficulty_calculator",
		"rating_calculator",
		"scores_combiner",
		"communities_combiner",
		"difficulty_calculator_config",
		"rating_calculator_config",
		"scores_combiner_count",
		"communities_combiner_count"
	)

	leaderboard_c.update_inputmodes(leaderboard.id, params.leaderboard.inputmodes)
	leaderboard_c.update_difftables(leaderboard.id, params.leaderboard.difftables)
	leaderboard_c.update_requirements(leaderboard.id, params.leaderboard.requirements)

	return {json = {leaderboard = leaderboard:to_name()}}
end

return leaderboard_c
