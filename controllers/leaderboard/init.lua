local Leaderboards = require("models.leaderboards")
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
	return additions.inputmodes.update_inputmodes(leaderboard_id, inputmodes)
end

leaderboard_c.update_difftables = function(leaderboard_id, difftables)
	return additions.difftables.update_difftables(leaderboard_id, difftables)
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

leaderboard_c.context.PATCH = util.add_owner_context("leaderboard", "context")
leaderboard_c.policies.PATCH = {
	{"authed", {community_role = "moderator"}},
	{"authed", {community_role = "admin"}},
	{"authed", {community_role = "creator"}},
}
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

	local found_leaderboard = Leaderboards:find({name = params.leaderboard.name})
	if found_leaderboard and found_leaderboard.id ~= leaderboard.id then
		return {status = 400, json = {message = "This name is already taken"}}
	end

	Leaderboards:for_db(params.leaderboard)
	util.patch(leaderboard, params.leaderboard, {
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
		"communities_combiner_count",
	})

	leaderboard_c.update_inputmodes(leaderboard.id, params.leaderboard.leaderboard_inputmodes)
	leaderboard_c.update_difftables(leaderboard.id, params.leaderboard.leaderboard_difftables)
	leaderboard_c.update_requirements(leaderboard.id, params.leaderboard.leaderboard_requirements)
	if params.leaderboard.leaderboard_inputmodes then
		leaderboard:get_leaderboard_inputmodes()
	end
	if params.leaderboard.leaderboard_difftables then
		leaderboard:get_leaderboard_difftables()
	end
	if params.leaderboard.leaderboard_requirements then
		leaderboard:get_leaderboard_requirements()
	end

	util.recursive_to_name(leaderboard)

	return {json = {leaderboard = leaderboard}}
end

leaderboard_c.context.DELETE = util.add_owner_context("leaderboard", "context")
leaderboard_c.policies.DELETE = {
	{"authed", {community_role = "admin"}},
	{"authed", {community_role = "creator"}},
}
leaderboard_c.DELETE = function(self)
	return {status = 204}
end

return leaderboard_c
