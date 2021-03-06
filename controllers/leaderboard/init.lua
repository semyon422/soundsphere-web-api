local Leaderboards = require("models.leaderboards")
local Communities = require("models.communities")
local Community_changes = require("models.community_changes")
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
leaderboard_c.policies.GET = {{"permit"}}
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

leaderboard_c.context.PATCH = {
	"leaderboard",
	"request_session",
	"session_user",
	"user_communities"
}
leaderboard_c.policies.PATCH = {
	{"authed", {leaderboard_role = "admin"}, {not_params = "transfer_ownership"}},
	{"authed", {leaderboard_role = "creator"}},
}
leaderboard_c.validations.PATCH = {
	{"leaderboard", type = "table", param_type = "body", validations = {
		{"name", type = "string"},
		{"description", type = "string"},
		{"banner", type = "string", optional = true, policies = "donator_policies"},
		{"owner_community_id", type = "number", range = {1}},
		{"difficulty_calculator", type = "string", one_of = Difficulty_calculators.list},
		{"rating_calculator", type = "string", one_of = Rating_calculators.list},
		{"scores_combiner", type = "string", one_of = Combiners.list},
		{"communities_combiner", type = "string", one_of = Combiners.list},
		{"difficulty_calculator_config", type = "number", default = 0},
		{"rating_calculator_config", type = "number", default = 0},
		{"scores_combiner_count", type = "number", default = 20},
		{"communities_combiner_count", type = "number", default = 100},
	}},
	{"transfer_ownership", type = "boolean", optional = true},
}
leaderboard_c.PATCH = function(self)
	local params = self.params
	local leaderboard = self.context.leaderboard

	local found_leaderboard = Leaderboards:find({name = params.leaderboard.name})
	if found_leaderboard and found_leaderboard.id ~= leaderboard.id then
		return {status = 400, json = {message = "This name is already taken"}}
	end

	local community = Communities:find(params.leaderboard.owner_community_id)
	if not community then
		return {status = 400, json = {message = "not community"}}
	end

	if params.transfer_ownership then
		local owner_community_id = leaderboard.owner_community_id
		leaderboard.owner_community_id = params.leaderboard.owner_community_id
		leaderboard:update("owner_community_id")
		Community_changes:add_change(
			self.context.session_user.id,
			owner_community_id,
			"transfer_ownership",
			leaderboard
		)
		return
	end

	if not leaderboard_c:check_policies(self, "donator_policies") then
		leaderboard.banner = ""
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

leaderboard_c.context.DELETE = {
	"leaderboard",
	"request_session",
	"session_user",
	"user_communities"
}
leaderboard_c.policies.DELETE = {
	{"authed", {leaderboard_role = "admin"}, {delete_delay = "leaderboard"}},
	{"authed", {leaderboard_role = "creator"}, {delete_delay = "leaderboard"}},
}
leaderboard_c.DELETE = function(self)
	local leaderboard = self.context.leaderboard

	local db = Leaderboards.db
	db.delete("community_leaderboards", {leaderboard_id = leaderboard.id})
	db.delete("leaderboard_difftables", {leaderboard_id = leaderboard.id})
	db.delete("leaderboard_users", {leaderboard_id = leaderboard.id})
	db.delete("leaderboard_scores", {leaderboard_id = leaderboard.id})
	db.delete("leaderboard_inputmodes", {leaderboard_id = leaderboard.id})
	db.delete("leaderboard_requirements", {leaderboard_id = leaderboard.id})

	leaderboard:delete()

	return {status = 204}
end

return leaderboard_c
